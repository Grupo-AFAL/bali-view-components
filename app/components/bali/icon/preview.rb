# frozen_string_literal: true

module Bali
  module Icon
    # Sibling constants are written in full (`Bali::Icon::LucideMapping`, not
    # `LucideMapping`) on purpose, and it is not style: `Module.nesting` is captured at parse
    # time and holds a reference to the module object. Lookbook loads this file at boot to
    # build its navigation; if a `reload!` runs afterwards, Zeitwerk discards that
    # `Bali::Icon` and creates another one, the sibling constant autoloads inside the new
    # one, and this class's nesting still points at the old one —
    # `uninitialized constant Bali::Icon::Preview::LucideMapping` over a constant that
    # `bin/rails runner` resolves without complaint (#843). The full name resolves against
    # the `Bali` in force at the time of the call.
    #
    # `test/requests/icon_previews_test.rb` forbids the pattern in every `preview.rb`.
    class Preview < ApplicationViewComponentPreview
      # Icon
      # ----
      # The Icon component renders icons from multiple sources with a consistent API.
      #
      # **Resolution order:**
      # 1. Lucide icons (primary) - consistent, modern stroke-based icons
      # 2. Kept icons (brands, regional) - payment processors, social media, flags
      # 3. Custom icons registered by the host through `Bali.custom_icons`
      #
      # @param name select { choices: [user, check, alert, trash, edit, search, home, settings, bell, star, heart, mail, phone, calendar, clock, download, upload, copy, filter, plus, minus, x, chevron-down, chevron-up, chevron-left, chevron-right, arrow-left, arrow-right] }
      # @param size select { choices: [~, small, medium, large] }
      def default(name: 'user', size: nil)
        render Icon::Component.new(name, size: size&.to_sym)
      end

      # Icon with custom styling
      # -------------------------
      # Add custom classes to style icons.
      #
      # @param name text
      # @param color select { choices: [text-primary, text-secondary, text-accent, text-success, text-warning, text-error, text-info] }
      def with_custom_class(name: 'star', color: 'text-primary')
        render Icon::Component.new(name, class: color)
      end

      # Lucide-mapped icons
      # -------------------
      # These icons use old Bali names but render using Lucide icons.
      # This provides visual consistency with the modern Lucide style.
      def lucide_mapped_icons
        render_with_template(
          template: 'bali/icon/previews/categorized',
          locals: {
            title: 'Lucide-Mapped Icons',
            description: 'Old Bali icon names that now render as Lucide icons',
            icons: Bali::Icon::LucideMapping.bali_names.sort
          }
        )
      end

      # Brand icons
      # -----------
      # Payment processors and social media logos.
      # These maintain their original styles since brand logos should be visually distinct.
      def brand_icons
        render_with_template(
          template: 'bali/icon/previews/categorized',
          locals: {
            title: 'Brand Icons',
            description: 'Payment processors and social media logos (kept from original Bali set)',
            icons: (Bali::Icon::KeptIcons::BRAND_PAYMENT + Bali::Icon::KeptIcons::BRAND_SOCIAL).sort
          }
        )
      end

      # Regional icons
      # --------------
      # Country flags and regional symbols.
      def regional_icons
        render_with_template(
          template: 'bali/icon/previews/categorized',
          locals: {
            title: 'Regional Icons',
            description: 'Country flags and regional symbols',
            icons: Bali::Icon::KeptIcons::REGIONAL.sort
          }
        )
      end

      # Custom domain icons
      # -------------------
      # Domain-specific icons without Lucide equivalents.
      def custom_domain_icons
        render_with_template(
          template: 'bali/icon/previews/categorized',
          locals: {
            title: 'Custom Domain Icons',
            description: 'Domain-specific icons for restaurant, medical, and other specialized uses',
            icons: Bali::Icon::KeptIcons::CUSTOM.sort
          }
        )
      end

      # All existing icons
      # ------------------
      # Every name the component resolves without reaching for a Lucide name
      # directly: the Bali names Lucide covers, the kept set, and anything the
      # host registered through `Bali.custom_icons`.
      def all_existing_icons
        names = Bali::Icon::LucideMapping.bali_names + Bali::Icon::KeptIcons::ALL +
                Bali.custom_icons.keys

        render_with_template(
          template: 'bali/icon/previews/default',
          locals: { icons: names.uniq.sort }
        )
      end

      # Direct Lucide usage
      # -------------------
      # You can also use Lucide icon names directly.
      # See https://lucide.dev/icons for the complete list.
      #
      # @param name text
      def direct_lucide(name: 'activity')
        render Icon::Component.new(name)
      end
    end
  end
end
