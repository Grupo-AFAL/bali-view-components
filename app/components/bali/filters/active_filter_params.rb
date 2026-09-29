# frozen_string_literal: true

module Bali
  module Filters
    # What a listing is narrowed by RIGHT NOW, written as the `[name, value]` pairs a form
    # can re-emit as hidden fields.
    #
    # Two surfaces need exactly this and used to have only half of it each: the quick-search
    # form inside `Filters::Component` (which must not clear the applied filters when it
    # submits), and a bulk action posting "act on the whole filtered result", which has to
    # tell the server WHICH result that is. Same serialization, one implementation — if the
    # two drifted, a bulk action would act on a different set than the listing showed.
    #
    # There are two halves to it because a listing can be narrowed from two shapes:
    #
    #   - the advanced builder's groups, which travel nested (`q[g][0][name_cont]`) and are
    #     rebuilt here out of the `filter_groups` state the panel renders;
    #   - everything flat: `filter_attribute` values, simple filters and the quick search,
    #     which live side by side under `q` and are what `FilterForm#active_filters` answers.
    module ActiveFilterParams
      module_function

      # Every pair that reproduces a listing's scope, given the form that produced it.
      #
      # Derived from the RESOLVED state, not from the raw request params, and that is the
      # point: with filter persistence on, a listing can arrive with an empty query string
      # and still be filtered by what the cache restored. Re-emitting the URL would say
      # "nothing is filtered" while the user looks at 3 of 200 rows.
      #
      # @param filter_form [Bali::FilterForm, nil]
      # @return [Array<Array(String, Object)>]
      # date_ranges arrive inside `active_filters` in both of their shapes (#966): the one
      # declared as an `attribute` travels RESOLVED (`start..end`, frozen — the shape
      # `DateRangeValue` casts back), and the simple filter travels RAW, so a preset
      # (`this_month`) goes as a token and the server resolves it again against its own clock.
      # `test_a_simple_date_range_is_emitted_exactly_once` warns if the two paths go back to
      # emitting the same `name` separately.
      def for_filter_form(filter_form)
        return [] if filter_form.nil?

        group_pairs(
          filter_form.try(:filter_groups) || [],
          combinator: filter_form.try(:applied_combinator)
        ) + flatten("q" => filter_form.try(:active_filters) || {})
      end

      # The applied state of the advanced builder, back in the Ransack param shape the filter
      # form submits. Only real conditions travel (attribute + value present); empty builder
      # rows stay out so the server keeps treating "search only, no filters" the way it does
      # when there are no filters at all. The consolidated `between` operator expands back to
      # its gteq/lteq pair.
      #
      # @param filter_groups [Array<Hash>]
      # @param combinator [String, nil] The top-level `q[m]` AS APPLIED — nil when the state
      #   carried none. Re-emitting the render default as if the user had chosen it flips an
      #   applied OR to AND on the next round-trip.
      # @return [Array<Array(String, Object)>]
      def group_pairs(filter_groups, combinator: nil)
        pairs = []

        Array(filter_groups).each_with_index do |group, index|
          conditions = (group[:conditions] || []).select { |condition| applied?(condition) }
          next if conditions.empty?

          pairs << [ "q[g][#{index}][m]", group[:combinator] ] if group[:combinator].present?
          conditions.each { |condition| pairs.concat(condition_pairs(condition, index)) }
        end

        pairs << [ "q[m]", combinator ] if pairs.any? && combinator.present?
        pairs
      end

      # Does this builder condition narrow anything? Empty rows are dropped AND so are the
      # ones that produce no real pair: a `between` with both ends blank passes `present?`
      # because it is a Hash, and used to emit a phantom group —just the `m`, without a single
      # condition—.
      #
      # It is the only definition of "applied condition" there is: both what TRAVELS
      # (`group_pairs`) and what is COUNTED (`FilterForm#active_filters_count`, the panel
      # badge) use it. Two different rules for the same question is how the advanced panel
      # fell out of `active_filters?` in the first place (#1085).
      #
      # @param condition [Hash] `{ attribute:, operator:, value: }` just as
      #   `FilterGroupParser` builds it
      def applied?(condition)
        condition[:attribute].present? && condition[:value].present? &&
          condition_pairs(condition, 0).any?
      end

      # What a host can write in `filter_params:`, in the shape the components need. The two
      # that accept the option normalize through here: without this, a nested hash passed
      # straight to an action came out as ONE hidden named `q` with the hash's `to_s` inside
      # it — a POST that looks well formed and filters nothing.
      #
      # @param value [Array<Array(String, Object)>, Hash, nil]
      # @return [Array<Array(String, Object)>]
      def normalize(value)
        return [] if value.blank?
        return value.to_a if value.is_a?(Array)
        return flatten(value) if value.is_a?(Hash)

        raise ArgumentError, "filter_params: expected [name, value] pairs or a nested hash " \
                             "(e.g. { q: { name_cont: 'Iron' } }), got #{value.class}"
      end

      # Nested params hash into `[name, value]` pairs.
      # e.g. `{ "sort" => { "column" => "name" } }` becomes `[["sort[column]", "name"]]`.
      def flatten(params, prefix = nil)
        (params || {}).flat_map do |key, value|
          field_name = prefix ? "#{prefix}[#{key}]" : key.to_s

          case value
          when Hash  then flatten(value, field_name)
          when Array then value.map { |v| [ "#{field_name}[]", v ] }
          else            [ [ field_name, value ] ]
          end
        end
      end

      def condition_pairs(condition, group_index)
        base = "q[g][#{group_index}][#{condition[:attribute]}"

        if condition[:operator] == "between"
          value = condition[:value] || {}
          [ [ "#{base}_gteq]", value[:start] || value["start"] ],
            [ "#{base}_lteq]", value[:end] || value["end"] ] ].reject { |_, v| v.blank? }
        elsif condition[:value].is_a?(Array)
          condition[:value].map { |v| [ "#{base}_#{condition[:operator]}][]", v ] }
        else
          [ [ "#{base}_#{condition[:operator]}]", condition[:value] ] ]
        end
      end
    end
  end
end
