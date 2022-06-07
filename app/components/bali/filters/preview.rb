# frozen_string_literal: true

module Bali
  module Filters
    class Preview < ApplicationViewComponentPreview
      FORM = Bali::Utils::DummyFilterForm.new

      def default
        render Bali::Filters::Component.new(form: FORM, url: '#', text_field: :name)
      end

      def with_filter_attributes
        render Bali::Filters::Component.new(form: FORM, url: '#', text_field: :name) do |c|
          c.attribute(
            title: 'Active',
            attribute: :status_in,
            collection_options: [['active', true], ['inactive', false]]
          )
        end
      end
    end
  end
end
