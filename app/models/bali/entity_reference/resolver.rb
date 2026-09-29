# frozen_string_literal: true

module Bali
  class EntityReference
    # #708 — the server side of the editor's `#`: it searches entities by text and resolves
    # `{entityType, entityId}` into the payload the chip paints. Everything it knows about
    # the host's models comes from `Bali.entity_reference_types`; the engine knows not one
    # class.
    #
    # The payload is a FROZEN CONTRACT with the JS (`useEntityReferences.jsx`):
    # `{entityType, entityId, entityName, url, broken}`. `extra_payload:` adds host keys on
    # top, but cannot clobber those five.
    class Resolver
      MAX_RESULTS = 10
      RESULTS_PER_TYPE = 5

      # A search that finds nothing walks EVERY registered type (the cut-off below only fires
      # with ten results in hand) and a LIKE with a leading wildcard cannot use the index.
      # With the `#` menu asking on every keystroke, a single letter is a full scan per type
      # that does not even narrow anything useful.
      MIN_QUERY_LENGTH = 2

      PAYLOAD_KEYS = %i[entityType entityId entityName url broken].freeze

      # An absent record is unreachable; any other notion of "broken" (archived, retired) is
      # supplied by the host with `unreachable?:`.
      DEFAULT_UNREACHABLE = ->(record) { record.nil? }

      # `controller` travels so that `permission_scope:` can read the host's session. Nothing
      # else uses it: the resolver runs just the same from a console or a job passing nil.
      def initialize(controller: nil, types: Bali.entity_reference_types)
        @controller = controller
        @types = types
      end

      # Autocomplete: N queries with LIMIT 5, cutting off as soon as there are enough. The
      # types are walked in the order the host declared them, so the registry also fixes
      # which category comes first in the menu.
      def search(query)
        query = query.to_s.strip
        return [] if query.length < MIN_QUERY_LENGTH

        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
        results = []

        @types.each do |type, config|
          results.concat(search_type(type, config, pattern))
          break if results.size >= MAX_RESULTS
        end

        results.first(MAX_RESULTS)
      end

      # Already-permitted refs (`[{"entityType" =>, "entityId" =>}]`) → payloads. A type that
      # is not in the registry and an id that no longer exists come out the same way:
      # `broken: true` with a nil `entityName`. The chip is painted broken instead of
      # disappearing from the document.
      def resolve(refs)
        Array(refs).group_by { |ref| ref["entityType"].to_s }.flat_map do |type, type_refs|
          ids = type_refs.filter_map { |ref| ref["entityId"].presence }
          config = @types[type]
          next ids.map { |id| broken_payload(type, id) } unless config

          found = lookup_scope(config).where(id: ids).index_by { |record| record.id.to_s }
          ids.map { |id| found[id] ? payload(type, found[id], config) : broken_payload(type, id) }
        end
      end

      private

      def search_type(type, config, pattern)
        scope = permitted(config, config[:search_scope].call)
        clause = matches_clause(scope, config[:search_fields], pattern)
        return [] unless clause

        scope.where(clause).limit(RESULTS_PER_TYPE).map { |record| payload(type, record, config) }
      end

      # `matches` generates a LIKE with a bind parameter, so the pattern (already escaped
      # with sanitize_sql_like) travels as a value and is never interpolated into the SQL.
      def matches_clause(scope, fields, pattern)
        table = scope.arel_table
        Array(fields).map { |field| table[field].matches(pattern) }.reduce(:or)
      end

      # The SAME gate in search and in resolution: if the host scopes a type by permissions,
      # a reference the reader cannot see resolves as broken instead of leaking them the
      # record's name. Without `permission_scope:` the scope passes through untouched.
      def permitted(config, scope)
        gate = config[:permission_scope]
        gate ? gate.call(@controller, scope) : scope
      end

      def lookup_scope(config)
        # `lookup_scope` is deliberately wider than `search_scope`: it includes archived and
        # retired records, which is what makes it possible to tell "broken" from
        # "nonexistent".
        permitted(config, config[:lookup_scope].call)
      end

      def payload(type, record, config)
        base = {
          entityType: type,
          entityId: record.id.to_s,
          entityName: record.public_send(config[:display_field]),
          url: config[:url]&.call(record),
          broken: unreachable?(config, record)
        }

        extra = config[:extra_payload]&.call(record)
        return base if extra.blank?

        # The contract keys win: an `extra_payload` that returns `broken` cannot turn a
        # broken record into a reachable one.
        extra.symbolize_keys.except(*PAYLOAD_KEYS).merge(base)
      end

      def broken_payload(type, id)
        { entityType: type, entityId: id.to_s, entityName: nil, url: nil, broken: true }
      end

      def unreachable?(config, record)
        (config[:unreachable?] || DEFAULT_UNREACHABLE).call(record)
      end
    end
  end
end
