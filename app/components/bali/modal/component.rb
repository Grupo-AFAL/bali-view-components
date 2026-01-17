# frozen_string_literal: true

module Bali
  module Modal
    class Component < ApplicationViewComponent
      SIZES = {
        sm: 'max-w-sm',
        md: 'max-w-md',
        lg: 'max-w-lg',
        xl: 'max-w-xl',
        full: 'max-w-full'
      }.freeze

      # Slot for modal header with title, optional badge, and close button
      renders_one :header,
                  lambda { |title:, badge: nil, badge_color: :primary, close_button: true, **opts|
                    Header::Component.new(
                      title: title,
                      badge: badge,
                      badge_color: badge_color,
                      close_button: close_button,
                      modal_id: modal_id,
                      **opts
                    )
                  }

      # Slot for modal body content
      renders_one :body, ->(**options) do
        Body::Component.new(modal_id: modal_id, **options)
      end

      # Slot for modal footer actions
      renders_one :actions, ->(**options) do
        Actions::Component.new(**options)
      end

      def initialize(active: true, size: nil, id: nil, **options)
        @active = active
        @size = size&.to_sym
        @wrapper_class = options.delete(:wrapper_class)
        @id = id
        @options = options
      end

      def modal_id
        @id || "modal-#{object_id}"
      end

      def title_id
        "#{modal_id}-title"
      end

      def description_id
        "#{modal_id}-description"
      end

      def modal_classes
        class_names(
          'modal-component',
          'modal',
          @active && 'modal-open',
          @options[:class]
        )
      end

      def box_classes
        class_names(
          'modal-box',
          SIZES[@size],
          @wrapper_class
        )
      end

      def stimulus_controller
        'modal'
      end

      # Check if we should render standalone close button (when no header slot)
      def render_standalone_close_button?
        !header?
      end

      # Check if we have describable content (body slot provides aria-describedby)
      def description?
        body?
      end
    end
  end
end
