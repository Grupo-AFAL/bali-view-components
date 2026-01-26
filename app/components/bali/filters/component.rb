# frozen_string_literal: true

module Bali
  module Filters
    class Component < ApplicationViewComponent
      include Utils::Url

      attr_reader :form, :url, :text_field, :opened, :auto_submit_search_input

      delegate :query_params, to: :form

      renders_many :attributes, ->(title:, attribute:, **options) do
        Bali::Filters::Attribute::Component.new(
          form: @form, title: title, attribute: attribute, **options
        )
      end

      renders_many :additional_query_params
      renders_one :custom_filters

      def initialize(form:, url:, text_field: nil, opened: false, **options)
        ActiveSupport::Deprecation.new('3.0', 'Bali').warn(
          'Bali::Filters is deprecated and will be removed in Bali 3.0. ' \
          'Use Bali::AdvancedFilters instead, which provides date range support ' \
          'and a more flexible filtering experience.'
        )

        @form = form
        @url = url
        @text_field = text_field
        @opened = filters_opened?(opened)
        @auto_submit_search_input = options.delete(:auto_submit_search_input)

        @options = prepend_class_name(options, 'width-inherit')
        @options = prepend_controller(@options, 'filter-form')
        @options = prepend_data_attribute(@options, 'filter-form-text-field-value', text_field)
        @options = prepend_data_attribute(@options, 'turbo-stream', true)

        add_auto_submit_data_to_options if @auto_submit_search_input
      end

      def filters_opened?(opened)
        !!ActiveRecord::Type::Boolean.new.cast(opened)
      end

      def active_filters_count
        @active_filters_count ||= (active_filters.keys & attribute_names).size
      end

      def active_filters?
        active_filters_count.positive?
      end

      def add_auto_submit_data_to_options
        @options = prepend_controller(@options, 'submit-on-change')
        @options = prepend_data_attribute(@options, 'submit-on-change-delay-value', 800)
        @options = prepend_data_attribute(
          @options, 'submit-on-change-response-kind-value', 'turbo-stream'
        )
      end

      def clear_filters_url
        add_query_param(url, :clear_filters, true)
      end

      private

      def attributes?
        attributes.any?
      end

      def active_filters
        @active_filters || query_params.except('s').compact_blank
      end

      def attribute_names
        attributes.map { |a| a.attribute.to_s }
      end
    end
  end
end
