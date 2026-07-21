# frozen_string_literal: true

module Bali
  module Modal
    class Component < ApplicationViewComponent
      SIZES = {
        sm: "max-w-sm",
        md: "max-w-md",
        lg: "max-w-lg",
        xl: "max-w-xl",
        full: "max-w-full"
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

      def initialize(active: true, size: nil, id: nil, confirm_on_close: false, confirm_close_message: nil, **options)
        @active = active
        @size = size&.to_sym
        @wrapper_class = options.delete(:wrapper_class)
        @id = id
        @confirm_on_close = confirm_on_close
        @confirm_close_message = confirm_close_message
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
          "modal-component",
          "modal",
          @active && "modal-open",
          @options[:class]
        )
      end

      def box_classes
        class_names(
          "modal-box",
          SIZES[@size],
          @wrapper_class
        )
      end

      def stimulus_controller
        "modal"
      end

      # Check if we should render standalone close button (when no header slot)
      def render_standalone_close_button?
        !header?
      end

      # Check if we have describable content (body slot provides aria-describedby)
      def description?
        body?
      end

      # Translated label for close button (accessibility)
      def close_label
        I18n.t("bali.modal.close", default: "Close modal")
      end

      # Opt-in confirm-on-close: when enabled, an unsaved form inside the modal
      # prompts before Escape/overlay/close-button discard the input. Rendering
      # its own `data-controller="modal"` scopes the confirm value to this modal
      # (the shared body/main-level controller ignores the nested subtree).
      def confirm_on_close?
        @confirm_on_close
      end

      def confirm_close_message
        @confirm_close_message.presence || I18n.t("bali.modal.confirm_close", default: "You have unsaved changes. Discard them?")
      end
    end
  end
end
