# frozen_string_literal: true

module Bali
  module Icon
    class Preview < ApplicationViewComponentPreview
      include Options

      def default
        render_with_template(template: 'bali/icon/previews/default', locals: { icons: MAP.keys })
      end

      def adding_a_class
        render Icon::Component.new('snowflake', class: 'has-text-info')
      end
    end
  end
end
