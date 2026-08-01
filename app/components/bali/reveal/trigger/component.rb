# frozen_string_literal: true

module Bali
  module Reveal
    module Trigger
      class Component < ApplicationViewComponent
        # `w-full text-left` restores what the <div> got for free: a button is
        # inline-block and centre-aligned until told otherwise.
        BASE_CLASSES = "reveal-trigger flex w-full text-left justify-between items-center pb-6 mb-6"
        BORDER_CLASSES = "border-b border-base-content/20"
        ICON_BASE_CLASSES = "trigger-icon h-3.5 rotate-[270deg] group-[.is-revealed]:rotate-0"

        renders_one :title

        def initialize(show_border: true, icon_class: nil, controls: nil, expanded: false, **options)
          @show_border = show_border
          @icon_class = icon_class
          @controls = controls
          @expanded = expanded
          @options = options
        end

        private

        attr_reader :show_border, :icon_class, :controls, :expanded, :options

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
            .merge(
              type: "button",
              class: trigger_classes,
              aria: { expanded: expanded, controls: controls }.compact.merge(options[:aria] || {})
            )
            .tap do |opts|
              prepend_action(opts, "click->reveal#toggle")
              opts[:data][:reveal_target] = "trigger"
            end
        end

        def icon_classes
          class_names(ICON_BASE_CLASSES, icon_class)
        end
      end
    end
  end
end
