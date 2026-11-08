# frozen_string_literal: true

module Bali
  module Testing
    # The guard an app's `Bali::Navigation::Base` subclass needs: a screen nobody placed falls to the first
    # module's menu without a word, and a namespace with a typo claims nothing.
    #
    #   require "bali/testing/navigation"
    #
    #   class NavigationTest < ActiveSupport::TestCase
    #     include Bali::Testing::Navigation
    #
    #     test "every screen has a place" do
    #       assert_navigation_covers_routes Navigation
    #     end
    #
    #     test "every title is translated" do
    #       assert_navigation_translated Navigation, locale: :es
    #     end
    #   end
    #
    # TEST-ONLY, and required explicitly rather than from `lib/bali.rb`: it constantizes every
    # routed controller.
    module Navigation
      # Every routed controller descending from `base` — what can draw the app's layout, engines'
      # included — is placed by the navigation or named by its `outside_menu`, and every entry
      # reaches a routed controller.
      #
      # @param navigation [Class<Bali::Navigation::Base>]
      # @param base [Class] the controllers that count as navigable
      # @param routes [ActionDispatch::Routing::RouteSet]
      def assert_navigation_covers_routes(navigation, base: ::ApplicationController, routes: Rails.application.routes)
        routed = bali_routed_controllers(routes)

        unplaced = routed.select { bali_navigable?(it, base) }.reject { navigation.claimed?(it) }
        assert_empty unplaced, "#{unplaced.sort.join(', ')} #{unplaced.one? ? 'has' : 'have'} no place in " \
                               "#{navigation.name || 'the navigation'}: add it to the `controllers:` of an item, " \
                               "a section or a module, or to `outside_menu`"

        unreached = navigation.controller_entries.reject do |entry|
          routed.any? { Bali::Navigation::Claim.covers?(entry, it) }
        end
        assert_empty unreached, "#{unreached.sort.join(', ')} #{unreached.one? ? 'reaches' : 'reach'} no routed " \
                                "controller: a typo, or a controller that is gone"
      end

      # Every title read from I18n exists in `locale`. A title is also the name analytics reads.
      #
      # @param navigation [Class<Bali::Navigation::Base>]
      # @param locale [Symbol]
      def assert_navigation_translated(navigation, locale: I18n.default_locale)
        missing = navigation.nodes.select(&:default_title?).map(&:title_key).reject { I18n.exists?(it, locale) }

        assert_empty missing, "Missing #{locale} translations: #{missing.join(', ')}"
      end

      private

      # `engine?` and `rack_app` are what `rails routes` walks engines with.
      def bali_routed_controllers(routes)
        routes.routes.flat_map { |route|
          route.app.engine? ? bali_routed_controllers(route.app.rack_app.routes) : Array(route.defaults[:controller])
        }.uniq
      end

      def bali_navigable?(controller_path, base)
        klass = "#{controller_path.camelize}Controller".safe_constantize
        klass.is_a?(Class) && klass < base
      end
    end
  end
end
