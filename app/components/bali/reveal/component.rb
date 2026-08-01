# frozen_string_literal: true

module Bali
  module Reveal
    class Component < ApplicationViewComponent
      BASE_CLASSES = "reveal-component select-none group"
      OPENED_CLASS = "is-revealed"

      # The trigger needs the id of the region it controls and the initial open
      # state; both are the parent's to know, so the slot is built here rather
      # than declared as a bare component class.
      renders_one :trigger, ->(**trigger_options) {
        Reveal::Trigger::Component.new(
          controls: content_id, expanded: opened, **trigger_options
        )
      }

      def initialize(opened: false, **options)
        @opened = opened
        @options = options
      end

      private

      attr_reader :opened, :options

      def content_id
        @content_id ||=
          if options[:id].present?
            "#{options[:id]}-content"
          else
            "reveal-content-#{SecureRandom.hex(4)}"
          end
      end

      def component_classes
        class_names(
          BASE_CLASSES,
          { OPENED_CLASS => opened },
          options[:class]
        )
      end

      def component_options
        options
          .except(:class)
          .merge(class: component_classes)
          .tap { |opts| prepend_controller(opts, "reveal") }
      end

      def content_classes
        "reveal-content mb-8 hidden group-[.is-revealed]:block"
      end
    end
  end
end
