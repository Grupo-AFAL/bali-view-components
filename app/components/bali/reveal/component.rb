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

      # @param content_class [String, nil] Extra classes for the revealed content box.
      #   Its bottom gap is `.reveal-content` in reveal/index.css (@layer components),
      #   so a utility passed here beats it: `content_class: "mb-0"` for a tight
      #   accordion. The box takes no options otherwise (#1148).
      def initialize(opened: false, content_class: nil, **options)
        @opened = opened
        @content_class = content_class
        @options = options
      end

      private

      attr_reader :opened, :content_class, :options

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

      # The gap under the content is `.reveal-content` in reveal/index.css, not a
      # utility here, for the same cascade reason as the trigger's spacing.
      def content_classes
        class_names("reveal-content hidden group-[.is-revealed]:block", content_class)
      end
    end
  end
end
