# frozen_string_literal: true

module Bali
  module Icon
    class Preview < ApplicationViewComponentPreview
      def default
        render Icon::Component.new('snowflake')
      end

      def adding_a_class
        render Icon::Component.new('snowflake', class: 'has-text-info')
      end
    end
  end
end
