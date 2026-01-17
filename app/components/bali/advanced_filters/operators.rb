# frozen_string_literal: true

module Bali
  module AdvancedFilters
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

      # Returns the localized label for a specific operator and type.
      # @param operator [String] The operator value (e.g., 'eq', 'cont')
      # @param type [Symbol, String] The field type
      # @return [String] The localized label or the operator value if not found
      def label_for(operator, type)
        for_type(type).find { |o| o[:value] == operator }&.dig(:label) || operator
      end

      private

      def text_operators
        [
          { value: 'cont', label: t_op('contains', 'contains') },
          { value: 'eq', label: t_op('equals', 'is exactly') },
          { value: 'start', label: t_op('starts_with', 'starts with') },
          { value: 'end', label: t_op('ends_with', 'ends with') },
          { value: 'not_cont', label: t_op('not_contains', 'does not contain') },
          { value: 'not_eq', label: t_op('not_equals', 'is not') }
        ]
      end

      def number_operators
        [
          { value: 'eq', label: '=' },
          { value: 'not_eq', label: '≠' },
          { value: 'gt', label: '>' },
          { value: 'lt', label: '<' },
          { value: 'gteq', label: '≥' },
          { value: 'lteq', label: '≤' }
        ]
      end

      def date_operators
        [
          { value: 'eq', label: t_op('on', 'is') },
          { value: 'between', label: t_op('between', 'between'), range: true },
          { value: 'gt', label: t_op('after', 'after') },
          { value: 'lt', label: t_op('before', 'before') },
          { value: 'gteq', label: t_op('on_or_after', 'on or after') },
          { value: 'lteq', label: t_op('on_or_before', 'on or before') }
        ]
      end

      def select_operators
        [
          { value: 'eq', label: t_op('is', 'is') },
          { value: 'not_eq', label: t_op('is_not', 'is not') },
          { value: 'in', label: t_op('is_any_of', 'is any of'), multiple: true },
          { value: 'not_in', label: t_op('is_not_any_of', 'is not any of'), multiple: true }
        ]
      end

      def boolean_operators
        [
          { value: 'eq', label: t_op('is', 'is') }
        ]
      end

      # Helper for I18n translations
      def t_op(key, default)
        I18n.t("bali.advanced_filters.operators.#{key}", default: default)
      end
    end
  end
end
