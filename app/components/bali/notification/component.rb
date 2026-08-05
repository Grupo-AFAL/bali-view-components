# frozen_string_literal: true

module Bali
  module Notification
    # Deprecated in v3, removed in v4. Split into {Bali::Toast::Component} (the
    # alert, which this subclasses) and {Bali::ToastContainer::Component} (the
    # fixed stack, which this still emits by hand when `fixed:` is on).
    #
    # Three keywords are translated here because the old names meant something
    # else: `type:` is `color:`, and `delay:` plus `dismiss:` collapse into a
    # single `duration:`. `dismiss:` in particular never had anything to do with
    # the close button — that button was always rendered, and the only way to hide
    # it was an `is-unclosable` class the gem never set. It is `closable:` now.
    class Component < Bali::Toast::Component
      # `danger` and `primary` were aliases: they rendered `alert-error` and
      # `alert-info`, the same classes `error` and `info` already rendered.
      LEGACY_COLORS = {
        danger: :error,
        primary: :info
      }.freeze

      LEGACY_POSITIONS = {
        top_right: :top_end,
        bottom_right: :bottom_end
      }.freeze

      def initialize(type: :success, delay: DEFAULT_DURATION, dismiss: true,
                     fixed: true, position: :bottom_right, **options)
        Bali.deprecator.warn(
          "Bali::Notification::Component is deprecated and is removed in 4.0. " \
          "Use Bali::Toast::Component inside a Bali::ToastContainer::Component: " \
          "`type:` is `color:`, `delay:`/`dismiss:` are one `duration:` (nil never " \
          "auto-closes), and `fixed:`/`position:` move to the container. " \
          "See docs/guides/migration-v2-to-v3.md."
        )

        @fixed = fixed
        @position = LEGACY_POSITIONS.fetch(position&.to_sym, position&.to_sym)

        key = type&.to_sym
        super(color: LEGACY_COLORS.fetch(key, key), duration: dismiss ? delay : nil, **options)
      end

      private

      def fixed? = @fixed

      def container_classes
        class_names(
          Bali::ToastContainer::Component::BASE_CLASSES,
          Bali::ToastContainer::Component::POSITIONS.fetch(
            @position, Bali::ToastContainer::Component::POSITIONS[:bottom_end]
          )
        )
      end
    end
  end
end
