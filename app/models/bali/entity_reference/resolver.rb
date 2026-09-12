# frozen_string_literal: true

module Bali
  class EntityReference
    # #708 — el lado servidor del `#` del editor: busca entidades por texto y resuelve
    # `{entityType, entityId}` al payload que el chip pinta. Todo lo que sabe de los modelos
    # del host viene de `Bali.entity_reference_types`; el engine no conoce ni una clase.
    #
    # El payload es CONTRATO CONGELADO con el JS (`useEntityReferences.jsx`):
    # `{entityType, entityId, entityName, url, broken}`. `extra_payload:` agrega claves del
    # host encima, pero no puede pisar esas cinco.
    class Resolver
      MAX_RESULTS = 10
      RESULTS_PER_TYPE = 5

      # Una búsqueda que no encuentra nada recorre TODOS los tipos registrados (el corte de
      # abajo solo dispara con diez resultados en mano) y un LIKE con comodín a la izquierda
      # no puede usar el índice. Con el menú del `#` pidiendo por tecleo, una sola letra es
      # un escaneo completo por tipo que además no acota nada útil.
      MIN_QUERY_LENGTH = 2

      PAYLOAD_KEYS = %i[entityType entityId entityName url broken].freeze

      # Un registro ausente es inalcanzable; cualquier otra noción de "roto" (archivado,
      # dado de baja) la pone el host con `unreachable?:`.
      DEFAULT_UNREACHABLE = ->(record) { record.nil? }

      # `controller` viaja para que `permission_scope:` pueda leer la sesión del host. Nada
      # más lo usa: el resolver corre igual desde consola o un job pasando nil.
      def initialize(controller: nil, types: Bali.entity_reference_types)
        @controller = controller
        @types = types
      end

      # Autocompletado: N consultas con LIMIT 5, cortando en cuanto hay suficientes. Los
      # tipos se recorren en el orden en que el host los declaró, así que el registry
      # también fija qué categoría sale primero en el menú.
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

      # Refs ya permitidas (`[{"entityType" =>, "entityId" =>}]`) → payloads. Un tipo que no
      # está en el registry y un id que ya no existe salen igual: `broken: true` con
      # `entityName` nulo. El chip se pinta roto en vez de desaparecer del documento.
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

      # `matches` genera un LIKE con bind parameter, así que el pattern (ya escapado con
      # sanitize_sql_like) viaja como valor y nunca se interpola en el SQL.
      def matches_clause(scope, fields, pattern)
        table = scope.arel_table
        Array(fields).map { |field| table[field].matches(pattern) }.reduce(:or)
      end

      # El MISMO gate en búsqueda y en resolución: si el host scopea un tipo por permisos,
      # una referencia que el lector no puede ver se resuelve como rota en vez de filtrarle
      # el nombre del registro. Sin `permission_scope:` el scope pasa intacto.
      def permitted(config, scope)
        gate = config[:permission_scope]
        gate ? gate.call(@controller, scope) : scope
      end

      def lookup_scope(config)
        # `lookup_scope` es a propósito más amplio que `search_scope`: incluye archivados y
        # dados de baja, que es lo que permite distinguir "roto" de "inexistente".
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

        # Las claves del contrato ganan: un `extra_payload` que devuelva `broken` no puede
        # convertir un registro roto en alcanzable.
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
