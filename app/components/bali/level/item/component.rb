# frozen_string_literal: true

module Bali
  module Level
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options, :text

        def initialize(text: nil, **options)
          @text = text
          @options = prepend_class_name(options, 'level-item')
        end

        def call
          tag.div(**options) do
            text || content
          end
        end
      end
    end
  end
end
