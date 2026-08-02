# frozen_string_literal: true

module Bali
  module ToastContainer
    class Preview < ApplicationViewComponentPreview
      # The whole flash hash goes in and every key the container recognises comes
      # out as a toast. v2's FlashNotifications took `notice:` and `alert:` only,
      # so `warning` and `info` were dropped without a word.
      #
      # @param position [Symbol] select [top_start, top_center, top_end, middle_start, middle_center, middle_end, bottom_start, bottom_center, bottom_end]
      # @param duration number
      def flash(position: :bottom_end, duration: 0)
        render ToastContainer::Component.new(
          position: position,
          duration: duration,
          flash: {
            notice: "Your changes have been saved.",
            alert: "Something went wrong. Please try again.",
            warning: "Two of the rows were skipped.",
            info: "The next import runs at midnight."
          }
        )
      end

      # Rails' own two keys, which is all an app that never set another one has.
      #
      # @param position [Symbol] select [top_start, top_center, top_end, middle_start, middle_center, middle_end, bottom_start, bottom_center, bottom_end]
      def notice_and_alert(position: :bottom_end)
        render ToastContainer::Component.new(
          position: position,
          duration: 0,
          flash: { notice: "Operation completed successfully", alert: "But there was a warning to review" }
        )
      end

      # Toasts can also be given one by one, which is what a page that is not
      # reporting on a flash does.
      #
      # @param position [Symbol] select [top_start, top_center, top_end, middle_start, middle_center, middle_end, bottom_start, bottom_center, bottom_end]
      def slots(position: :top_end)
        render ToastContainer::Component.new(position: position) do |container|
          container.with_toast(color: :info, duration: nil) { "One toast." }
          container.with_toast(color: :success, duration: nil) { "Another toast." }
        end
      end
    end
  end
end
