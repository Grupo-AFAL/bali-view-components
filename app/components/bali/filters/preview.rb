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

          c.attribute(
            title: 'Single Option',
            attribute: :date_gteq,
            collection_options: [
              ['7 days', Date.today - 7.days],
              ['14 days', Date.today - 14.days]
            ],
            multiple: false
          )
        end
      end
    end
  end
end
