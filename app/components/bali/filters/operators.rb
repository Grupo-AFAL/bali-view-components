# frozen_string_literal: true

module Bali
  module Filters
    # Centralized operator definitions for all filter field types.
    # Used by Component, Condition::Component, and AppliedTags::Component.
    # Also serialized to JSON for the JavaScript condition controller.
    module Operators
      extend self

      OPERATOR_METHODS = {
        text: :text_operators,
        number: :number_operators,
        date: :date_operators,
        datetime: :date_operators,
        select: :select_operators,
        boolean: :boolean_operators
      }.freeze

      # Returns operators for a given field type with localized labels.
      # @param type [Symbol, String] :text, :number, :date, :datetime, :select, or :boolean
      # @return [Array<Hash>] Operator hashes with :value, :label, and optional :multiple
      def for_type(type)
        method_name = OPERATOR_METHODS.fetch(type.to_sym, :text_operators)
        send(method_name)
      end

      # The operators the panel offers for one attribute: its type's, narrowed to and ordered
      # by its `operators:` when it declares them (`FilterForm.filter_attribute`, which raises
      # on one the type does not offer). An attribute hash built in a view or in an
      # `available_attributes` override skips that check, so an unknown entry is ignored here.
      #
      # @param attribute [Hash] `{ type:, operators: }`, as `FilterForm#available_attributes`
      #   builds it
      # @return [Array<Hash>]
      def for_attribute(attribute)
        offered = for_type(attribute[:type] || :text)
        allowed = Array(attribute[:operators]).map { |operator| RansackParamName.text_predicate(operator) }
        return offered if allowed.empty?

        allowed.filter_map { |value| offered.find { |operator| operator[:value] == value } }.presence || offered
      end

      # The operator a condition opens on when the user picks the attribute: its
      # `default_operator:`, else the first of its `operators:`. nil when it declares neither,
      # and the row keeps the operator it had. condition/component.html.erb writes it as the
      # attribute option's `data-default-operator`, which condition_controller.js#attributeChanged
      # reads.
      #
      # @param attribute [Hash] `{ type:, operators:, default_operator: }`
      # @return [String, nil]
      def default_for(attribute)
        return if attribute[:default_operator].blank? && attribute[:operators].blank?

        offered = for_attribute(attribute).map { |operator| operator[:value] }
        requested = RansackParamName.text_predicate(attribute[:default_operator])
        offered.include?(requested) ? requested : offered.first
      end

      # The Ransack predicates the panel writes for the attribute: one per operator, and the
      # `gteq`/`lteq` pair a range operator ("between") travels as.
      #
      # @param attribute [Hash] `{ type:, operators: }`
      # @return [Array<String>]
      def predicates_for(attribute)
        for_attribute(attribute).flat_map { |operator| operator[:range] ? %w[gteq lteq] : operator[:value] }.uniq
      end

      # Returns the localized label for a specific operator and type.
      # @param operator [String] The operator value (e.g., 'eq', 'cont')
      # @param type [Symbol, String] The field type
      # @return [String] The localized label or the operator value if not found
      def label_for(operator, type)
        current = RansackParamName.text_predicate(operator)
        for_type(type).find { |o| o[:value] == current }&.dig(:label) || operator
      end

      private

      # "contains" and its kin in the variant the installed ransack wants (#1530).
      def text_operators
        [
          { value: text("cont"), label: t_op("contains") },
          { value: "eq", label: t_op("equals") },
          { value: text("start"), label: t_op("starts_with") },
          { value: text("end"), label: t_op("ends_with") },
          { value: text("not_cont"), label: t_op("not_contains") },
          { value: "not_eq", label: t_op("not_equals") }
        ]
      end

      def text(predicate)
        RansackParamName.text_predicate(predicate)
      end

      def number_operators
        [
          { value: "eq", label: "=" },
          { value: "not_eq", label: "≠" },
          { value: "gt", label: ">" },
          { value: "lt", label: "<" },
          { value: "gteq", label: "≥" },
          { value: "lteq", label: "≤" }
        ]
      end

      def date_operators
        [
          { value: "eq", label: t_op("on") },
          { value: "between", label: t_op("between"), range: true },
          { value: "gt", label: t_op("after") },
          { value: "lt", label: t_op("before") },
          { value: "gteq", label: t_op("on_or_after") },
          { value: "lteq", label: t_op("on_or_before") }
        ]
      end

      def select_operators
        [
          { value: "eq", label: t_op("is") },
          { value: "not_eq", label: t_op("is_not") },
          { value: "in", label: t_op("is_any_of"), multiple: true },
          { value: "not_in", label: t_op("is_not_any_of"), multiple: true }
        ]
      end

      def boolean_operators
        [
          { value: "eq", label: t_op("is") }
        ]
      end

      def t_op(key)
        I18n.t("bali_view.filters.operators.#{key}")
      end
    end
  end
end
