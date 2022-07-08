# frozen_string_literal: true

module Bali
  module Timeline
    module Item
      class Component < ApplicationViewComponent
        attr_reader :heading, :icon, :options

        def initialize(heading: nil, icon: nil, **options)
          @heading = heading
          @icon = icon
          @options = prepend_class_name(options, 'timeline-item')
        end
      end
    end
  end
end
