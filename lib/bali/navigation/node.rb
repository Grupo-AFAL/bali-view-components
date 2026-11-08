# frozen_string_literal: true

module Bali
  module Navigation
    # One entry of a declared navigation. Built by the class methods of `Bali::Navigation::Base`;
    # read by `locate`, `Bali::Navigation::Menu` and the two components.
    class Node
      attr_reader :navigation, :key, :parent, :children, :gate, :controllers, :index

      def initialize(navigation:, key:, parent:, index:, gate: nil, controllers: [], title: nil)
        @navigation = navigation
        @key = key
        @parent = parent
        @index = index
        @gate = gate
        @controllers = controllers
        @title = title
        @children = []
      end

      # The literal `title:`, or the translation under the navigation's `i18n_scope`.
      #
      # @param locale [Symbol]
      # @return [String]
      def title(locale: I18n.locale)
        default_title? ? I18n.t(title_key, locale: locale) : @title
      end

      # @return [String] the I18n key a title without `title:` is read from
      def title_key
        "#{navigation.i18n_scope}.#{self.class::I18N_GROUP}.#{key}"
      end

      # @return [Boolean] whether the title comes from I18n
      def default_title?
        !@title.is_a?(String)
      end

      # @return [Array<Node>] the parent first, the top-level node last
      def ancestors
        parent ? [ parent, *parent.ancestors ] : []
      end

      # @return [AppModule, nil]
      def app_module
        [ self, *ancestors ].find { |node| node.is_a?(AppModule) }
      end

      # @return [Section, nil]
      def section
        [ self, *ancestors ].find { |node| node.is_a?(Section) }
      end

      def item?
        false
      end

      def inspect
        "#<#{self.class.name} #{key.inspect}>"
      end
    end

    # An entry of the module switcher (`Bali::SideMenu`'s `with_menu_switch`).
    class AppModule < Node
      I18N_GROUP = "modules"

      attr_reader :icon, :landing

      def initialize(icon: nil, landing: nil, **)
        super(**)
        @icon = icon
        @landing = landing
      end
    end

    # A list of the side menu, under its heading.
    class Section < Node
      I18N_GROUP = "sections"

      def initialize(heading: true, implicit: false, **)
        super(**)
        @heading = heading
        @implicit = implicit
      end

      def heading?
        @heading
      end

      # The section holding the items written directly in an `app_module`.
      def implicit?
        @implicit
      end

      # An implicit section is headed by its module's title.
      def title(locale: I18n.locale)
        implicit? ? parent.title(locale: locale) : super
      end

      def default_title?
        !implicit? && super
      end
    end

    # An expandable entry holding items.
    class Group < Node
      I18N_GROUP = "items"

      attr_reader :icon

      def initialize(icon: nil, **)
        super(**)
        @icon = icon
      end
    end

    # A destination.
    class Item < Node
      I18N_GROUP = "items"

      attr_reader :path, :icon, :badge, :target, :hint, :keywords, :match

      def initialize(path:, icon: nil, badge: nil, target: nil, hint: nil, keywords: nil, menu: true,
                     match: :crud, **)
        super(**)
        @path = path
        @icon = icon
        @badge = badge
        @target = target
        @hint = hint
        @keywords = keywords
        @menu = menu
        @match = match
      end

      def item?
        true
      end

      # False for an item offered only by the command palette.
      def menu?
        @menu != false
      end
    end
  end
end
