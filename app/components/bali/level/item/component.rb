# frozen_string_literal: true

module Bali
  module Level
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options, :text

        def initialize(text: nil, **options)
          @text = text
          @class = options.delete(:class)
          @options = options
        end

        def classes
          "level-item #{@class}"
        end

        def call
          tag.div class: classes, **options do
            text || content
          end
        end
      end
    end
  end
end
