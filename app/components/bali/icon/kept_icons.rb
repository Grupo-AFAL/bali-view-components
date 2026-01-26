# frozen_string_literal: true

module Bali
  module Icon
    # Icons that are kept from the original Bali icon set because Lucide
    # doesn't have equivalents. These are primarily:
    # - Brand/logo icons (payment processors, social media)
    # - Regional icons (country flags)
    # - Domain-specific custom icons
    #
    # These icons maintain their original styles (mostly filled FontAwesome-style)
    # rather than Lucide's stroked style, which is acceptable for brand logos
    # since they're meant to be visually distinct.
    #
    class KeptIcons
      # Payment processor and credit card brand icons
      BRAND_PAYMENT = %w[
        american-express
        mastercard
        visa
        paypal
        oxxo
      ].freeze

      # Social media and platform icons
      BRAND_SOCIAL = %w[
        facebook
        facebook-square
        instagram
        instagram-square
        twitter
        linkedin
        pinterest
        youtube
        github
        whatsapp
        whatsapp-square
        outlook
      ].freeze

      # Regional/country-specific icons
      REGIONAL = %w[
        mexico-flag
        us-flag
      ].freeze

      # Custom domain-specific icons without Lucide equivalents
      # These are used in specific business contexts (restaurant, medical, etc.)
      CUSTOM = %w[
        comment-dollar
        day
        diagnose
        month
        nested-arrow
        recipe-book
        space-station-moon-alt
        ticket
        week
      ].freeze

      # All kept icon names
      ALL = (BRAND_PAYMENT + BRAND_SOCIAL + REGIONAL + CUSTOM).freeze

      class << self
        # Check if an icon name should be served from kept icons
        #
        # @param name [String, Symbol] the icon name
        # @return [Boolean]
        def exists?(name)
          ALL.include?(name.to_s)
        end

        # Find and return the SVG for a kept icon
        # Delegates to DefaultIcons for the actual SVG content
        #
        # @param name [String, Symbol] the icon name
        # @return [String] the SVG markup
        # @raise [Options::IconNotAvailable] if icon doesn't exist
        def find(name)
          name_str = name.to_s
          unless exists?(name_str)
            raise Options::IconNotAvailable,
                  "Icon: '#{name}' is not a kept icon"
          end

          # Delegate to DefaultIcons for the actual SVG
          constant_name = name_str.upcase.tr('-', '_')
          DefaultIcons.const_get(constant_name).html_safe
        end

        # Check if an icon is a brand icon
        #
        # @param name [String, Symbol] the icon name
        # @return [Boolean]
        def brand?(name)
          (BRAND_PAYMENT + BRAND_SOCIAL).include?(name.to_s)
        end

        # Check if an icon is a regional icon
        #
        # @param name [String, Symbol] the icon name
        # @return [Boolean]
        def regional?(name)
          REGIONAL.include?(name.to_s)
        end

        # Check if an icon is a custom domain-specific icon
        #
        # @param name [String, Symbol] the icon name
        # @return [Boolean]
        def custom?(name)
          CUSTOM.include?(name.to_s)
        end
      end
    end
  end
end
