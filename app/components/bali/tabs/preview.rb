# frozen_string_literal: true

module Bali
  module Tabs
    class Preview < ApplicationViewComponentPreview
      def default
        render(Tabs::Component.new) do |c|
          c.tab(title: 'Tab 1', active: true) do
            tag.p('Tab one content')
          end

          c.tab(title: 'Tab 2') do
            tag.p('Tab two content')
          end

          c.tab(title: 'Tab 3') do
            tag.p('Tab three content')
          end
        end
      end
    end
  end
end
