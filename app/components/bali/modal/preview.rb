# frozen_string_literal: true

module Bali
  module Modal
    # The panel is a native `<dialog>`, and `ModalController` opens it with
    # `showModal()`: the top layer, the inertness of the page behind it and the
    # focus containment all come from the element. A panel rendered `active:`
    # is promoted the same way when its controller connects, which is what these
    # previews show — the preview frame behind the panel is inert while it is open.
    class Preview < ApplicationViewComponentPreview
      # @param active toggle
      # @param size [Symbol] select [~, sm, md, lg, xl, full]
      def default(active: true, size: nil)
        render_with_template(locals: { active: active, size: size })
      end

      # @label With Slots
      # Use slots for structured modal content with header, body, and actions.
      # The header slot positions badges correctly and includes a close button.
      # @param active toggle
      # @param size [Symbol] select [~, sm, md, lg, xl, full]
      def with_slots(active: true, size: nil)
        render_with_template(locals: { active: active, size: size })
      end

      # @label With Header Badge
      # Header slot supports badges that are right-aligned.
      # @param active toggle
      # @param badge_color select [primary, secondary, accent, info, success, warning, error]
      def with_header_badge(active: true, badge_color: :info)
        render_with_template(locals: { active: active, badge_color: badge_color })
      end

      # @label Form Modal
      # Example of a modal containing a form with action buttons.
      # @param active toggle
      def form_modal(active: true)
        render_with_template(locals: { active: active })
      end
    end
  end
end
