# frozen_string_literal: true

module Bali
  module Reveal
    module Trigger
      class Component < ApplicationViewComponent
        # `w-full text-left` restores what the <div> got for free: a button is
        # inline-block and centre-aligned until told otherwise.
        # The bottom spacing is NOT here: it lives in reveal/index.css, inside
        # @layer components, so a host utility on the trigger can beat it. Written
        # in this attribute it could not be beaten without `!` — see that sheet.
        BASE_CLASSES = "reveal-trigger flex w-full text-left justify-between items-center"
        BORDER_CLASSES = "border-b border-base-content/20"
        # Same story for the chevron's height: `h-3.5` used to sit here, next to
        # whatever `icon_class` the caller passed, so `icon_class: "h-2"` lost the
        # tie and `h-6` won by luck. It is `.trigger-icon` in reveal/index.css now.
        # The rotation stays: its state variant has to share a layer with it.
        ICON_BASE_CLASSES = "trigger-icon rotate-[270deg] group-[.is-revealed]:rotate-0"

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
