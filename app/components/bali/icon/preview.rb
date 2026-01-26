# frozen_string_literal: true

module Bali
  module Icon
    class Preview < ApplicationViewComponentPreview
      # Icon
      # ----
      # The Icon component renders icons from multiple sources with a consistent API.
      #
      # **Resolution order:**
      # 1. Lucide icons (primary) - consistent, modern stroke-based icons
      # 2. Kept icons (brands, regional) - payment processors, social media, flags
      # 3. Legacy icons - backwards compatibility fallback
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
            icons: LucideMapping.bali_names.sort
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
            icons: (KeptIcons::BRAND_PAYMENT + KeptIcons::BRAND_SOCIAL).sort
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
            icons: KeptIcons::REGIONAL.sort
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
            icons: KeptIcons::CUSTOM.sort
          }
        )
      end

      # All existing icons (legacy)
      # ---------------------------
      # Complete list of all available icons for backwards compatibility.
      def all_existing_icons
        render_with_template(
          template: 'bali/icon/previews/default',
          locals: { icons: Bali::Icon::Options.icons.keys.sort }
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
