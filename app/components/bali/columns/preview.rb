# frozen_string_literal: true

module Bali
  module Columns
    class Preview < ApplicationViewComponentPreview
      def default
        render Columns::Component.new do |c|
          c.column(class: 'is-half') do
            tag.p 'First Column'
          end

          c.column(class: 'is-half') do
            tag.p 'Second Column'
          end
        end
      end
    end
  end
end
