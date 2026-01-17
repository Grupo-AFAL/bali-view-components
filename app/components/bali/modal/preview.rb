# frozen_string_literal: true

module Bali
  module Modal
    class Preview < ApplicationViewComponentPreview
      # @param active toggle
      # @param size [Symbol] select [~, sm, md, lg, xl, full]
      def default(active: true, size: nil)
        render Modal::Component.new(active: active, size: size) do
          tag.div class: 'space-y-4' do
            safe_join([
                        tag.h3('Modal Title', class: 'text-lg font-bold'),
                        tag.p('This is the modal content. You can put anything here.')
                      ])
          end
        end
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
      # @param badge_color [Symbol] select [primary, secondary, accent, info, success, warning, error]
      def with_header_badge(active: true, badge_color: :info)
        render Modal::Component.new(active: active, size: :md) do |modal|
          modal.with_header(title: 'User Details', badge: 'New', badge_color: badge_color)
          modal.with_body do
            tag.div class: 'space-y-2' do
              safe_join([
                tag.p('Name: John Doe'),
                tag.p('Email: john@example.com'),
                tag.p('Role: Administrator')
              ])
            end
          end
        end
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
