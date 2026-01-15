# frozen_string_literal: true

module Bali
  module AdvancedFilters
    class Component < ApplicationViewComponent
      include Utils::Url

      attr_reader :url, :available_attributes, :apply_mode, :id, :popover

      # Renders the applied filter pills above the filter builder
      renders_one :applied_tags, ->(**options) do
        AppliedTags::Component.new(
          filter_groups: @filter_groups,
          available_attributes: @available_attributes,
          url: @url,
          **options
        )
      end

      # @param url [String] The URL to submit filters to
      # @param available_attributes [Array<Hash>] Available filterable attributes
      #   Each hash should have: { key:, label:, type:, options: (for select) }
      #   Types: :text, :number, :date, :datetime, :select, :boolean
      # @param filter_groups [Array<Hash>] Initial filter state (from URL params)
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param combinator [Symbol] :and (default) or :or - how groups are combined
      # @param max_groups [Integer] Maximum number of filter groups allowed
      # @param popover [Boolean] Whether to show filters in a popover (default: true)
      # @param button_text [String] Text for the popover trigger button
      def initialize(
        url:,
        available_attributes:,
        filter_groups: [],
        apply_mode: :batch,
        combinator: :and,
        max_groups: 10,
        popover: true,
        button_text: nil,
        **options
      )
        @url = url
        @available_attributes = normalize_attributes(available_attributes)
        @filter_groups = filter_groups.presence || [default_filter_group]
        @apply_mode = apply_mode
        @combinator = combinator.to_s
        @max_groups = max_groups
        @popover = popover
        @button_text = button_text
        @id = options.delete(:id) || "advanced-filters-#{SecureRandom.hex(4)}"

        @options = options
      end

      def combinator
        @combinator
      end

      def filter_groups
        @filter_groups
      end

      def max_groups
        @max_groups
      end

      def button_text
        @button_text || I18n.t('bali.advanced_filters.filters_button', default: 'Filters')
      end

      def active_filter_count
        @filter_groups.sum do |group|
          group[:conditions]&.count { |c| c[:attribute].present? && c[:value].present? } || 0
        end
      end

      def has_active_filters?
        active_filter_count > 0
      end

      # Serialize attributes for Stimulus controller
      def attributes_json
        @available_attributes.map do |attr|
          {
            key: attr[:key].to_s,
            label: attr[:label],
            type: attr[:type].to_s,
            options: attr[:options] || [],
            operators: operators_for_type(attr[:type])
          }
        end.to_json
      end

      # Build the default operators for each attribute type
      def operators_for_type(type)
        case type.to_sym
        when :text
          [
            { value: 'cont', label: I18n.t('bali.advanced_filters.operators.contains', default: 'contains') },
            { value: 'eq', label: I18n.t('bali.advanced_filters.operators.equals', default: 'is exactly') },
            { value: 'start', label: I18n.t('bali.advanced_filters.operators.starts_with', default: 'starts with') },
            { value: 'end', label: I18n.t('bali.advanced_filters.operators.ends_with', default: 'ends with') },
            { value: 'not_cont', label: I18n.t('bali.advanced_filters.operators.not_contains', default: 'does not contain') },
            { value: 'not_eq', label: I18n.t('bali.advanced_filters.operators.not_equals', default: 'is not') }
          ]
        when :number
          [
            { value: 'eq', label: '=' },
            { value: 'not_eq', label: '≠' },
            { value: 'gt', label: '>' },
            { value: 'lt', label: '<' },
            { value: 'gteq', label: '≥' },
            { value: 'lteq', label: '≤' }
          ]
        when :date, :datetime
          [
            { value: 'eq', label: I18n.t('bali.advanced_filters.operators.on', default: 'is') },
            { value: 'gt', label: I18n.t('bali.advanced_filters.operators.after', default: 'after') },
            { value: 'lt', label: I18n.t('bali.advanced_filters.operators.before', default: 'before') },
            { value: 'gteq', label: I18n.t('bali.advanced_filters.operators.on_or_after', default: 'on or after') },
            { value: 'lteq', label: I18n.t('bali.advanced_filters.operators.on_or_before', default: 'on or before') }
          ]
        when :select
          [
            { value: 'eq', label: I18n.t('bali.advanced_filters.operators.is', default: 'is') },
            { value: 'not_eq', label: I18n.t('bali.advanced_filters.operators.is_not', default: 'is not') },
            { value: 'in', label: I18n.t('bali.advanced_filters.operators.is_any_of', default: 'is any of'), multiple: true },
            { value: 'not_in', label: I18n.t('bali.advanced_filters.operators.is_not_any_of', default: 'is not any of'), multiple: true }
          ]
        when :boolean
          [
            { value: 'eq', label: I18n.t('bali.advanced_filters.operators.is', default: 'is') }
          ]
        else
          [
            { value: 'eq', label: I18n.t('bali.advanced_filters.operators.equals', default: 'equals') },
            { value: 'cont', label: I18n.t('bali.advanced_filters.operators.contains', default: 'contains') }
          ]
        end
      end

      private

      def normalize_attributes(attributes)
        attributes.map do |attr|
          {
            key: attr[:key],
            label: attr[:label] || attr[:key].to_s.humanize,
            type: attr[:type] || :text,
            options: attr[:options] || []
          }
        end
      end

      def default_filter_group
        {
          combinator: 'or',
          conditions: [default_condition]
        }
      end

      def default_condition
        {
          attribute: '',
          operator: 'cont',
          value: ''
        }
      end
    end
  end
end
