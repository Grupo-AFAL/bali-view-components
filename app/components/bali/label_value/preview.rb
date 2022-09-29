# frozen_string_literal: true

module Bali
  module LabelValue
    class Preview < ApplicationViewComponentPreview
      def default
        render LabelValue::Component.new(label: 'Name', value: 'Juan Perez')
      end
    end
  end
end
