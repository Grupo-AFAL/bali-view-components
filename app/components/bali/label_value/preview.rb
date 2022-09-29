# frozen_string_literal: true

module Bali
  module LabelValue
    class Preview < ApplicationViewComponentPreview
      def default
        render LabelValue::Component.new(label: 'Name', value: 'Juan Perez')
      end

      def with_content
        render LabelValue::Component.new(label: 'URL') do |c|
          c.link_to 'Download link', '#'
        end
      end
    end
  end
end
