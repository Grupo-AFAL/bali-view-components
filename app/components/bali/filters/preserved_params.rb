# frozen_string_literal: true

module Bali
  module Filters
    # What of a listing's state survives a filter submit or a Clear link, with ONE semantic:
    # the query parsed from `url:` minus EXCLUDED_PARAMS, plus the explicit
    # `preserved_params:` hash, deduplicated with explicit winning.
    #
    # A GET submit replaces the action's query string with the form's fields, so anything
    # living in the listing URL (a host scope, `page`, `sort`) is lost unless it is re-emitted
    # as hidden fields: `Filters::Component` and `DataTable::SimpleFilters::Component` paint
    # them in their forms. `Filters::AppliedTags::Component` is no form; it builds its Clear all
    # link from the same pairs.
    #
    # Includers must set `@url` and `@preserved_params` in their initializer.
    module PreservedParams
      # `saved_view` is NOT preserved: re-sending it makes the server re-apply the view's
      # payload, silently trampling the filters or the search the user has just typed.
      # (`page` does travel: preserving it is deliberate Bali behaviour.)
      # filters_controller.js builds on these hidden fields, not on `url:`'s query, for the URL it
      # pushes and the ones Clear and the search's × visit.
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

      # `url:` as a Clear link visits it. `clear_filters` is what deletes the filter cache: the bare
      # URL reads to the server as "no filter came in", which with persistence on RESTORES what
      # was just cleared. The pairs after it are the hidden fields', so the view's state stays.
      def clear_filters_url
        uri = URI.parse(@url)
        uri.query = URI.encode_www_form([ %w[clear_filters true] ] + preserved_query_params)
        uri.to_s
      end

      # Render hidden fields for preserved params (call from template).
      # `id: nil` because these fields can be painted in more than one form of the same
      # document (in popover mode they go in the quick-search one AND in the panel one), and
      # with an id derived from the name they left duplicate ids behind.
      def preserved_params_hidden_fields
        safe_join(
          preserved_query_params.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) }
        )
      end

      private

      # Nested params hash into [name, value] pairs.
      # e.g., {"sort" => {"column" => "name"}} becomes [["sort[column]", "name"]]
      def flatten_params(params, prefix = nil)
        ActiveFilterParams.flatten(params, prefix)
      end
    end
  end
end
