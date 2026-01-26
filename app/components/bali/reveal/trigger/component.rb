# frozen_string_literal: true

module Bali
  module Reveal
    module Trigger
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'reveal-trigger flex justify-between items-center pb-6 mb-6'
        BORDER_CLASSES = 'border-b border-base-content/20'
        ICON_BASE_CLASSES = 'trigger-icon h-3.5 rotate-[270deg] group-[.is-revealed]:rotate-0'

        renders_one :title

        def initialize(show_border: true, icon_class: nil, **options)
          @show_border = show_border
          @icon_class = icon_class
          @options = options
        end

        private

        attr_reader :show_border, :icon_class, :options

        def trigger_classes
          class_names(
            BASE_CLASSES,
            { BORDER_CLASSES => show_border },
            options[:class]
          )
        end

        def trigger_options
          options
            .except(:class)
            .merge(class: trigger_classes)
            .tap { |opts| prepend_action(opts, 'click->reveal#toggle') }
        end

        def icon_classes
          class_names(ICON_BASE_CLASSES, icon_class)
        end
      end
    end
  end
end
