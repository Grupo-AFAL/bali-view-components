# frozen_string_literal: true

module Bali
  module Filters
    # Shared semantics for what a filter form carries through its GET submit.
    #
    # A GET submit replaces the action's query string with the form's fields, so
    # anything living in the listing URL (a host scope, `page`, `sort`) is lost
    # unless it is re-emitted as hidden fields. Both `Filters::Component` and
    # `DataTable::SimpleFilters::Component` include this module so the two forms
    # preserve params with ONE semantic: query params parsed from `url:` plus the
    # explicit `preserved_params:` hash, deduplicated with explicit winning.
    #
    # Includers must set `@url` and `@preserved_params` in their initializer.
    module PreservedParams
      # `saved_view` NO se preserva: re-enviarlo hace que el server re-aplique el payload de
      # la vista, pisando en silencio los filtros o la búsqueda que el usuario acaba de
      # escribir. (`page` sí viaja: preservarlo es comportamiento deliberado de Bali.)
      EXCLUDED_PARAMS = %w[q clear_filters clear_search saved_view].freeze

      # Extract non-filter query params to preserve them when submitting.
      # Combines params parsed from the URL with any explicitly-passed
      # `preserved_params` (e.g. an active `group_by`), which win on key
      # collisions. Returns an array of [name, value] pairs for hidden_field_tag.
      def preserved_query_params
        query_string = URI.parse(@url).query
        from_url = if query_string.blank?
                     []
        else
                     params = Rack::Utils.parse_nested_query(query_string)
                     flatten_params(params.except(*EXCLUDED_PARAMS))
        end

        explicit = flatten_params(@preserved_params.stringify_keys).reject { |_, value| value.to_s.blank? }
        explicit_keys = explicit.map(&:first)
        from_url.reject { |name, _| explicit_keys.include?(name) } + explicit
      end

      # Render hidden fields for preserved params (call from template).
      # `id: nil` porque estos campos pueden pintarse en más de un form del mismo documento
      # (en modo popover van en el de búsqueda rápida Y en el del panel), y con id derivado
      # del name quedaban ids duplicados.
      def preserved_params_hidden_fields
        safe_join(
          preserved_query_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
        )
      end

      private

      # Recursively flatten nested params hash into [name, value] pairs.
      # e.g., {"sort" => {"column" => "name"}} becomes [["sort[column]", "name"]]
      def flatten_params(params, prefix = nil)
        params.flat_map do |key, value|
          field_name = prefix ? "#{prefix}[#{key}]" : key.to_s

          case value
          when Hash  then flatten_params(value, field_name)
          when Array then value.map { |v| [ "#{field_name}[]", v ] }
          else            [ [ field_name, value ] ]
          end
        end
      end
    end
  end
end
