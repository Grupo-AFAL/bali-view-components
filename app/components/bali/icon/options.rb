# frozen_string_literal: true

module Bali
  module Icon
    # Lookup over the icons Bali ships as literal SVG markup: the kept set
    # (brands, flags, domain-specific) plus whatever the host registers through
    # `Bali.custom_icons`.
    #
    # Lucide-backed names are deliberately absent — they have no markup of their
    # own until lucide-rails renders one at a given size. `Bali::Icon::Component`
    # is what resolves every source, and what templates should use.
    class Options
      class IconNotAvailable < StandardError; end

      class << self
        # Icons that exist as SVG strings, by name
        #
        # @return [Hash<String, String>] icon name => SVG content
        def icons
          @icons ||= KeptIcons.all.merge(Bali.custom_icons)
        end

        # Returns just the icon names
        #
        # @return [Array<String>]
        def icon_names
          icons.keys
        end

        # Find an icon by name
        #
        # @param name [String, Symbol] the icon name
        # @return [String] SVG markup
        # @raise [IconNotAvailable] if icon not found
        def find(name)
          name_str = name.to_s
          raise IconNotAvailable, "Icon: '#{name}' is not available" unless icons.key?(name_str)

          icons[name_str].html_safe
        end

        # Check if an icon exists
        #
        # @param name [String, Symbol] the icon name
        # @return [Boolean]
        def exists?(name)
          icons.key?(name.to_s)
        end

        # Clear cached icons (useful for testing or when custom icons change)
        def reset!
          @icons = nil
        end
      end
    end
  end
end
