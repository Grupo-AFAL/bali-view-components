# frozen_string_literal: true

module Bali
  class FilterForm
    # EnumCasting translates enum LABELS to their VALUES before the params reach Ransack.
    #
    # Symptom: filtering Status = "Done" returned exactly the opposite records.
    # Cause: Ransack casts with the column's RAW type (Ransack::Nodes::Value#cast through
    # Context#type_for, which reads `column.type` and never ActiveRecord's EnumType), so over
    # an integer enum `"done".to_i` is 0 — the value of `draft`. `AR.where(status: "done")`
    # gets it right because EnumType does run there; the same value through Ransack does not.
    # And it fails INVERTED and in silence: "draft" also casts to 0, so half the filters look
    # like they work.
    #
    # Over STRING enums this already worked (cast_to_string does not break the label and
    # EnumType resolves it afterwards), so translating there is idempotent: `"action"` and
    # `"Action"` produce the same SQL. The translation does not change that, it only makes it
    # explicit.
    module EnumCasting
      extend ActiveSupport::Concern

      # The predicates where the value IS a member of the enum. NOT an arbitrary list: it is
      # exactly the one the advanced UI offers for a `type: :select` attribute
      # (Bali::Filters::Operators.select_operators) — a test pins them together so they cannot
      # be separated. Outside of it the value is not a membership and translating it would
      # change the question: `_cont` asks for a SUBSTRING (over `enum kind: { a: "alpha" }`,
      # searching "a" would become searching "alpha"), and `_gteq` asks for an ORDER over the
      # raw codes, a meaning Rails does not promise and Bali cannot invent.
      EQUALITY_PREDICATES = %w[eq not_eq in not_in].freeze

      # Ransack keys that are NOT conditions: the combinator, the sorts and the `c` form
      # (conditions as an array), which Bali does not emit and which has an entirely different
      # structure.
      RESERVED_KEYS = %w[m s c].freeze

      # Groupings nest: a group can carry another `g` inside it.
      GROUPING_KEYS = %w[g groupings].freeze

      # Suffix of the compound predicates (`status_eq_any`), which ask the same thing as their
      # base predicate over several values.
      COMPOUND_SUFFIX = /_(any|all)\z/

      private

      def cast_enum_labels(params)
        params.each_with_object({}) do |(key, value), casted|
          name = key.to_s
          casted[key] =
            if GROUPING_KEYS.include?(name)
              cast_enum_groupings(value)
            elsif RESERVED_KEYS.include?(name)
              value
            else
              cast_enum_condition(name, value)
            end
        end
      end

      # A NESTED `g` can arrive as an array (Ransack accepts both forms and the normalization
      # in FilterForm#extract_groupings only reaches the top level): without this branch the
      # inner group dodged the translation and returned the opposite records.
      def cast_enum_groupings(groupings)
        return groupings.map { |group| cast_enum_group(group) } if groupings.is_a?(Array)
        return groupings unless groupings.is_a?(Hash)

        groupings.transform_values { |group| cast_enum_group(group) }
      end

      def cast_enum_group(group)
        group.is_a?(Hash) ? cast_enum_labels(group) : group
      end

      def cast_enum_condition(key, value)
        predicate = Ransack::Predicate.detect_from_string(key)
        return value if predicate.nil?
        return value unless EQUALITY_PREDICATES.include?(predicate.sub(COMPOUND_SUFFIX, ""))

        mapping = enum_mappings[key.delete_suffix("_#{predicate}")]
        return value if mapping.nil?

        return value.map { |member| cast_enum_member(mapping, member) } if value.is_a?(Array)

        cast_enum_member(mapping, value)
      end

      # Three cases, not two. A known LABEL is translated. A known RAW value passes through
      # intact, so an app that was already sending `0`/`1` keeps working the same. And ANY
      # OTHER thing over an integer enum becomes a sentinel that cannot match anybody: letting
      # it through is reintroducing the whole bug, because Ransack casts it with the column's
      # raw type and `"completed".to_i` —a renamed member, a capitalized `"Done"`, a typo— is
      # 0, that is, the FIRST member of the enum. With the sentinel, `eq`/`in` return nothing
      # and `not_eq`/`not_in` return everything: the honest answer to a question about a member
      # that does not exist, instead of another member's answer.
      #
      # A STRING enum needs no sentinel (an unknown label no longer matches anything), and an
      # EMPTY value cannot have one either: Ransack ignores blank conditions, so mapping it
      # would turn an unchosen select into "show nothing".
      def cast_enum_member(mapping, value)
        return value unless value.is_a?(String) || value.is_a?(Symbol)
        return value if value.blank?

        member = value.to_s
        return mapping[member] if mapping.key?(member)
        return value if mapping.values.any? { |raw| raw.to_s == member }
        return value unless mapping.values.all?(Integer)

        mapping.values.max + 1
      end

      # `defined_enums` and not `scope.model`: a relation delegates it to its class, but a
      # scope that ALREADY is the class (`FilterForm.new(Movie, params)` — the form Ransack's
      # own API teaches) does not answer `model`, and asking there turned the whole module into
      # a silent no-op with the original bug intact. A scope with no enums (the test doubles)
      # does not answer either and the module is a no-op, which is correct: there is nothing to
      # translate.
      #
      # Only the OWN model's enums. A `studio_status_eq` points at the associated model's enum,
      # and resolving it forces replicating Ransack's association resolution (multi-level,
      # `ransackable_associations`, polymorphic suffixes): getting that wrong reintroduces
      # exactly the wrong-data-wearing-a-correct-face bug this fixes. It is left out on purpose
      # and the hook to extend it is this method — until then, a select over an ASSOCIATION's
      # enum returns the opposite records and its `options:` have to be declared with the raw
      # values.
      def enum_mappings
        @enum_mappings ||= scope.respond_to?(:defined_enums) ? scope.defined_enums : {}
      end
    end
  end
end
