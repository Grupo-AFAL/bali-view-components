# frozen_string_literal: true

module Bali
  module LabelValue
    class Preview < ApplicationViewComponentPreview
      # @param label text "The label text displayed above the value"
      # @param value text "The value to display"
      def default(label: 'Name', value: 'Juan Perez')
        render LabelValue::Component.new(label: label, value: value)
      end

      # Use block content for rich content like links or formatted text.
      # Block content is only used when `value:` parameter is nil.
      def with_content
        render LabelValue::Component.new(label: 'URL') do
          tag.a 'Download link', href: '#', class: 'link link-primary'
        end
      end
    end
  end
end
