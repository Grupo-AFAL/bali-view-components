# frozen_string_literal: true

module Bali
  module ToastContainer
    # The fixed stack a `Bali::Toast` lives in.
    #
    # This is the half of v2's `Bali::Notification` that was not about the alert
    # itself -- `fixed:` and `position:` -- pulled out into the one component that
    # owns it, plus what `Bali::FlashNotifications` did. It reads the whole flash
    # hash rather than the two keys `FlashNotifications` accepted, so
    # `flash[:warning]` and `flash[:info]` stop being silently dropped.
    class Component < ApplicationViewComponent
      # daisyUI's `.toast` is the stack: `position: fixed`, a flex column, a gap
      # between entries, and no z-index of its own -- hence the token, so a toast
      # reports above the modal it is reporting on.
      BASE_CLASSES = "toast toast-container-component z-[var(--bali-z-toast)]"

      # daisyUI spells the axes separately, so the nine combinations are written
      # out: Tailwind's scanner only keeps a class it can see as a literal.
      POSITIONS = {
        top_start: "toast-top toast-start",
        top_center: "toast-top toast-center",
        top_end: "toast-top toast-end",
        middle_start: "toast-middle toast-start",
        middle_center: "toast-middle toast-center",
        middle_end: "toast-middle toast-end",
        bottom_start: "toast-bottom toast-start",
        bottom_center: "toast-bottom toast-center",
        bottom_end: "toast-bottom toast-end"
      }.freeze

      # Which flash key means which colour. `notice` and `alert` are Rails' own two;
      # the rest are the names apps set by hand. A key that is not here is left
      # alone rather than rendered as something generic -- `flash[:timedout]` and
      # friends are state, not messages.
      FLASH_COLORS = {
        notice: :success,
        success: :success,
        alert: :error,
        error: :error,
        danger: :error,
        warning: :warning,
        info: :info
      }.freeze

      renders_many :toasts, Bali::Toast::Component

      def initialize(flash: nil, position: :bottom_end,
                     duration: Bali::Toast::Component::DEFAULT_DURATION, **options)
        @flash = flash
        @position = position&.to_sym
        @duration = duration
        @options = prepend_class_name(options, container_classes)
      end

      # [colour, message] for every flash entry this component knows how to show.
      def flash_entries
        return [] if @flash.blank?

        @flash.filter_map do |key, message|
          color = FLASH_COLORS[key.to_sym]
          next if color.nil? || message.blank?

          [ color, message ]
        end
      end

      private

      attr_reader :duration, :options

      def container_classes
        class_names(BASE_CLASSES, POSITIONS.fetch(@position, POSITIONS[:bottom_end]))
      end
    end
  end
end
