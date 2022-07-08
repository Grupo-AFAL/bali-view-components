# frozen_string_literal: true

module Bali
  module Timeline
    module Header
      class Component < ApplicationViewComponent
        attr_reader :text, :tag_class, :options

        def initialize(text:, tag_class: nil, **options)
          @text = text
          @tag_class = tag_class
          @options = prepend_class_name(options, 'timeline-header')
        end
      end
    end
  end
end
