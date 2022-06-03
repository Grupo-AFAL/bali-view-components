# frozen_string_literal: true

module Bali
  module Icon
    class Preview < ApplicationViewComponentPreview
      def default
        render Icon::Component.new('snowflake')
      end

      # @param classes text
      def adding_a_class(classes: 'has-text-info')
        render Icon::Component.new('snowflake', class: classes)
      end
    end
  end
end
