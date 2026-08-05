# frozen_string_literal: true

module Bali
  module Message
    # Deprecated in v3, removed in v4. Renamed to {Bali::Alert::Component}, which
    # this subclasses: the markup, the slots and every keyword except the two
    # translated below are unchanged, so this is a warning rather than a behaviour
    # change — with one exception, called out in the migration guide: the default
    # ARIA role is derived from the colour now, so a non-error message announces as
    # `status` instead of interrupting the screen reader as `alert`.
    class Component < Bali::Alert::Component
      # The Bulma-era colour names, and what they actually rendered. `primary`,
      # `secondary` and `link` were three spellings of two daisyUI classes.
      LEGACY_COLORS = {
        primary: :info,
        secondary: :neutral,
        link: :info,
        danger: :error
      }.freeze

      def initialize(color: :primary, dismissible: false, **options)
        Bali.deprecator.warn(
          "Bali::Message::Component is deprecated and is removed in 4.0. " \
          "Use Bali::Alert::Component: `color:` takes the daisyUI names " \
          "(:neutral, :info, :success, :warning, :error) and `dismissible:` is now " \
          "`closable:`. See docs/guides/migration-v2-to-v3.md."
        )

        key = color&.to_sym
        super(color: LEGACY_COLORS.fetch(key, key), closable: dismissible, **options)
      end
    end
  end
end
