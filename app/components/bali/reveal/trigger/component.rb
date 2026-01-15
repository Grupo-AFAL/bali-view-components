# frozen_string_literal: true

module Bali
  module Reveal
    module Trigger
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :title

        def initialize(show_border: true, **options)
          @icon_class = options.delete(:icon_class)

          trigger_classes = 'reveal-trigger flex justify-between items-center pb-6 mb-6'
          @options = prepend_class_name(options, trigger_classes)
          @options = prepend_action(@options, 'click->reveal#toggle')

          @options = prepend_class_name(@options, 'border-b border-base-content/20') if show_border
        end
      end
    end
  end
end
