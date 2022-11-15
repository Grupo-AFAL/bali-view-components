# frozen_string_literal: true

module Bali
  module Filters
    class Component < ApplicationViewComponent
      attr_reader :form, :url, :text_field, :opened, :auto_submit_search_input

      delegate :query_params, to: :form

      renders_many :attributes, ->(title:, attribute:, collection_options:, multiple: true) do
        Bali::Filters::Attribute::Component.new(
          form: @form,
          title: title,
          attribute: attribute,
          collection_options: collection_options,
          multiple: multiple
        )
      end

      renders_many :additional_query_params

      def initialize(form:, url:, text_field: nil, opened: false, **options)
        @form = form
        @url = url
        @text_field = text_field
        @opened = filters_opened?(opened)
        @auto_submit_search_input = options.delete(:auto_submit_search_input)
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

      def form_data
        if auto_submit_search_input
          return {
            controller: 'filter-form submit-on-change',
            'filter-form-text-field-value': text_field,
            'submit-on-change-delay-value': 200,
            'submit-on-change-response-kind-value': 'turbo-stream'
          }
        end

        { controller: 'filter-form', 'filter-form-text-field-value': text_field }
      end

      private

      def attributes?
        attributes.any?
      end

      def active_filters
        @active_filters || query_params.except('s').filter { |_k, v| v.present? }
      end

      def attribute_names
        attributes.map { |a| a.attribute.to_s }
      end
    end
  end
end
