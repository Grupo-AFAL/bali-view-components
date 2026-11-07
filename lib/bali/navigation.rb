# frozen_string_literal: true

require_relative "navigation/node"
require_relative "navigation/location"

module Bali
  # An app's navigation, declared once: app modules (optional) → sections → items, from which
  # `Bali::SideMenu` and `Bali::Command` draw themselves (`navigation:`) and which answers where
  # a controller belongs (`locate`).
  #
  # Whatever depends on the person or the request — a gate, a path, a landing, a badge — is a
  # lambda run with `instance_exec` in the view, where `main_app`, the engines' route proxies,
  # `policy` and `current_user` exist. Bali names no user, permission or policy library.
  #
  # @example
  #   class Navigation < Bali::Navigation
  #     authorize { |keys| Array(keys).any? { current_user.can?(it) } }
  #
  #     app_module :finance, icon: "landmark", controllers: %w[finance] do
  #       item :finance_cfdis, icon: "file-text", path: :finance_cfdis_path,
  #            gate: "finance.fiscal.view", controllers: %w[finance/cfdis]
  #     end
  #   end
  #
  # See docs/guides/navigation.md.
  class Navigation
    # A node and one of its `controllers:` entries, or an `outside_menu` entry (no node).
    Claim = Struct.new(:node, :entry, :index) do
      def self.covers?(entry, path)
        path == entry || path.start_with?("#{entry}/")
      end

      def matches?(path)
        self.class.covers?(entry, path)
      end
    end

    class << self
      # How this app reads a gate that is not a Proc — a permission key, a Pundit pair. Runs in
      # the view with the gate as its argument. Declare it before the first such gate.
      #
      # @yieldparam gate [Object] the `gate:` value, as written
      # @yieldreturn [Boolean]
      def authorize(&block)
        @authorizer = block
      end

      # @return [Proc, nil]
      attr_reader :authorizer

      # The I18n scope titles are read from: `<scope>.modules.<key>`, `<scope>.sections.<key>`,
      # `<scope>.items.<key>`.
      #
      # @param scope [String, nil] the new scope; nil reads the current one
      # @return [String] `"navigation"` unless set
      def i18n_scope(scope = nil)
        scope ? @i18n_scope = scope.to_s : (@i18n_scope || "navigation")
      end

      # What the request counts as, when it is not its own `controller_path`: a controller that
      # serves screens of several modules. Runs in the view.
      #
      # @yieldreturn [String] a controller path
      def current_controller_path(&block)
        @controller_path_resolver = block
      end

      # @return [Proc, nil]
      attr_reader :controller_path_resolver

      # An entry of the module switcher. Every top-level node is a module, or none is. Items
      # written directly inside it form a section headed by the module's title.
      #
      # @param key [Symbol] unique in the navigation; the title's I18n key
      # @param icon [String, nil] Lucide icon name
      # @param gate [Proc, Object, nil] zero-arity Proc run in the view, or a value for `authorize`
      # @param landing [Symbol, String, Proc, nil] where the switcher goes; the first item drawn
      #   in its side menu when nil
      # @param controllers [Array<String>] namespaces it claims: each one and everything under it
      # @param title [String, nil] a literal title instead of the I18n one
      # @return [AppModule]
      def app_module(key, icon: nil, gate: nil, landing: nil, controllers: [], title: nil, &block)
        reject_nested!(:app_module, key) if building
        reject_mixed_top_level!(AppModule, key)
        build(AppModule, key, block, icon:, gate:, landing:, controllers:, title:)
      end

      # A list of the side menu, inside an `app_module` or at the top level.
      #
      # @param key [Symbol] unique in the navigation; the title's I18n key
      # @param gate [Proc, Object, nil] zero-arity Proc run in the view, or a value for `authorize`
      # @param controllers [Array<String>] namespaces it claims: each one and everything under it
      # @param title [String, nil] a literal title instead of the I18n one
      # @param heading [Boolean] false draws the list without a heading; the title still names
      #   the section in the palette and in `locate`
      # @return [Section]
      def section(key, gate: nil, controllers: [], title: nil, heading: true, &block)
        reject_nested!(:section, key) unless building.nil? || building.is_a?(AppModule)
        reject_mixed_top_level!(Section, key) if building.nil?
        build(Section, key, block, gate:, controllers:, title:, heading:)
      end

      # An expandable entry of a section. Its children are items; it has no path of its own.
      #
      # @param key [Symbol] unique in the navigation; the title's I18n key (under `items`)
      # @param icon [String, nil] Lucide icon name
      # @param gate [Proc, Object, nil] zero-arity Proc run in the view, or a value for `authorize`
      # @param title [String, nil] a literal title instead of the I18n one
      # @return [Group]
      def group(key, icon: nil, gate: nil, title: nil, &block)
        reject_nested!(:group, key) if building.is_a?(Group)
        build(Group, key, block, parent: entry_parent(:group, key), icon:, gate:, title:)
      end

      # A destination.
      #
      # @param key [Symbol] unique in the navigation; the title's I18n key
      # @param path [Symbol, String, Proc] a `main_app` route helper, a URL, or a Proc run in the
      #   view. Resolved only when drawn
      # @param icon [String, nil] Lucide icon name
      # @param gate [Proc, Object, nil] zero-arity Proc run in the view, or a value for `authorize`
      # @param controllers [Array<String>] namespaces it claims: each one and everything under it
      # @param badge [Proc, nil] run in the view when the item is drawn; nil draws no badge
      # @param target [String, nil] `"_blank"` and the like; such an item stays out of the palette
      # @param hint [String, nil] the link's `title`, and search text in the palette
      # @param keywords [String, Array<String>, Proc, nil] more search text for the palette
      # @param menu [Boolean] false offers the item in the palette only
      # @param match [Symbol] `Bali::SideMenu::Item`'s path matching, for when no claim decides
      # @param title [String, nil] a literal title instead of the I18n one
      # @return [Item]
      def item(key, path: nil, icon: nil, gate: nil, controllers: [], badge: nil, target: nil, hint: nil,
               keywords: nil, menu: true, match: :crud, title: nil)
        raise ArgumentError, "item #{key.inspect} has no path:" if path.nil?

        build(Item, key, nil, parent: entry_parent(:item, key), path:, icon:, gate:, controllers:, badge:,
                              target:, hint:, keywords:, menu:, match:, title:)
      end

      # Navigable controllers that deliberately have no place in the menu.
      #
      # @param namespaces [Array<String>] each one and everything under it
      def outside_menu(*namespaces)
        namespaces.flatten.map(&:to_s).each do |entry|
          validate_entry!(:outside_menu, entry)
          own_claims << Claim.new(nil, entry, next_index)
        end
        @claims = nil
      end

      # @return [Array<Node>] the top-level nodes, in order
      def roots
        @roots ||= []
      end

      # @return [Array<Node>] every node, in declaration order
      def nodes
        @nodes ||= []
      end

      # @return [Array<AppModule>]
      def app_modules
        roots.grep(AppModule)
      end

      def app_modules?
        roots.first.is_a?(AppModule)
      end

      # @param key [Symbol]
      # @return [Node, nil]
      def find(key)
        registry[key]
      end

      # Where a controller belongs. The winning claim is the entry with the most segments; on a
      # tie, the one whose ancestors' longest matching entry has the most; on a tie, the first
      # declared. Nil when nothing claims the path, or when an `outside_menu` entry wins.
      #
      # @param controller_path [String]
      # @return [Location, nil]
      def locate(controller_path)
        winner = claims_for(controller_path).max_by { |claim| [ *rank(claim, controller_path), -claim.index ] }
        Location.for(winner.node) if winner&.node
      end

      # @return [Boolean] whether a node or an `outside_menu` entry claims the path
      def claimed?(controller_path)
        claims_for(controller_path).any?
      end

      # @return [Array<String>] every `controllers:` and `outside_menu` entry
      def controller_entries
        claims.map(&:entry).uniq
      end

      # @return [Array<Claim>] the claims that match the path
      def claims_for(controller_path)
        path = controller_path.to_s
        claims.select { |claim| claim.matches?(path) }
      end

      # Rules 1 and 2 of `locate`: the entry's segments, then its ancestors' support.
      #
      # @return [Array(Integer, Integer)]
      def rank(claim, controller_path)
        [ segments(claim.entry), support(claim, controller_path.to_s) ]
      end

      private

      def build(klass, key, block, parent: building, controllers: [], **options)
        reject_duplicate!(key)
        validate_gate!(key, options[:gate])
        controllers = Array(controllers).map(&:to_s).each { |entry| validate_entry!(key, entry) }

        node = klass.new(navigation: self, key: key, parent: parent, index: next_index, controllers:, **options)
        add(node)
        if block
          building_stack.push(node)
          begin
            block.call
          ensure
            building_stack.pop
          end
        end
        raise ArgumentError, "#{klass.name.demodulize.underscore} #{key.inspect} has no items" if !node.item? && node.children.empty?

        node
      end

      def add(node)
        (node.parent ? node.parent.children : roots) << node
        nodes << node
        registry[node.key] = node if node.key
        @claims = nil
      end

      # Items and groups written directly in a module go into its implicit section.
      def entry_parent(kind, key)
        raise ArgumentError, "#{kind} #{key.inspect} is outside any section or module" if building.nil?
        return building unless building.is_a?(AppModule)

        last = building.children.last
        return last if last.is_a?(Section) && last.implicit?

        Section.new(navigation: self, key: nil, parent: building, index: next_index, implicit: true).tap { add(it) }
      end

      def building
        building_stack.last
      end

      def building_stack
        @building_stack ||= []
      end

      def registry
        @registry ||= {}
      end

      def own_claims
        @own_claims ||= []
      end

      def claims
        @claims ||= (nodes.flat_map { |node| node.controllers.map { Claim.new(node, it, node.index) } } + own_claims)
                    .sort_by(&:index)
      end

      def next_index
        @next_index = (@next_index || 0) + 1
      end

      def segments(entry)
        entry.count("/") + 1
      end

      def support(claim, path)
        return 0 unless claim.node

        claim.node.ancestors.flat_map(&:controllers).select { Claim.covers?(it, path) }.map { segments(it) }.max || 0
      end

      def reject_duplicate!(key)
        raise ArgumentError, "#{key.inspect} is declared twice" if registry.key?(key)
      end

      def reject_nested!(kind, key)
        raise ArgumentError, "#{kind} #{key.inspect} cannot go inside #{building.class.name.demodulize.underscore} " \
                             "#{building.key.inspect}"
      end

      def reject_mixed_top_level!(klass, key)
        return if roots.empty? || roots.first.is_a?(klass)

        raise ArgumentError, "#{key.inspect}: the top level holds app modules or sections, not both"
      end

      def validate_gate!(key, gate)
        return if gate.nil?

        if gate.is_a?(Proc)
          return if gate.arity.zero?

          raise ArgumentError, "the gate of #{key.inspect} takes arguments: gates run in the view, use current_user"
        end
        return if authorizer

        raise ArgumentError, "the gate of #{key.inspect} is not a Proc: declare `authorize` before it"
      end

      def validate_entry!(key, entry)
        entry = entry.to_s
        return unless entry.empty? || entry.start_with?("/") || entry.end_with?("/") || entry.include?("#")

        raise ArgumentError, "#{key.inspect}: #{entry.inspect} is not a controller namespace"
      end
    end
  end
end
