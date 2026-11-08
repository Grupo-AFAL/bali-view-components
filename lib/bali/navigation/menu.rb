# frozen_string_literal: true

module Bali
  module Navigation
    # A navigation as one request sees it: what the person may open, where the request sits, and
    # each path resolved. `navigation_for(Navigation)` builds it once per view; outside a view,
    # `Navigation.menu(context)` takes any object answering what the gates call.
    #
    # Visibility comes from gates alone and paths are resolved only when drawn, once per menu: the
    # side menu and the palette share it, so a route both draw is generated once. A menu built for
    # visibility never touches a route. It is lazy: a module stops at its first visible item.
    class Menu
      attr_reader :navigation

      # @param navigation [Class<Bali::Navigation::Base>]
      # @param context [Object] the view, or any object answering what the gates call
      def initialize(navigation, context)
        @navigation = navigation
        @context = context
        @visible = {}.compare_by_identity
        @paths = {}.compare_by_identity
        @landings = {}.compare_by_identity
      end

      # @return [Array<AppModule>] the modules this person may open, in order
      def app_modules
        @app_modules ||= navigation.app_modules.select { offered?(it) }
      end

      # The location among what this person may open. Items that tie on a shared controller are
      # told apart by their path's query: the one whose parameters the request carries, the most
      # of them first.
      #
      # @return [Location, nil]
      def location
        return @location if defined?(@location)

        best = navigation.best_claims(controller_path) { it.node.nil? || offered?(it.node) }
        best = by_query(best) if best.many?
        winner = best.min_by(&:index)
        @location = (Location.for(winner.node) if winner&.node)
      end

      # @return [AppModule, nil] the location's module, or the first one this person may open
      def current_app_module
        location&.app_module || app_modules.first
      end

      # @return [Array<Section>] the sections this person may open: the current module's, or the
      #   navigation's own without modules
      def sections
        roots = navigation.app_modules? ? current_app_module&.children || [] : navigation.roots
        roots.select { offered?(it) }
      end

      # @param container [Section, Group]
      # @return [Array<Item, Group>] what the side menu draws in it
      def items(container)
        container.children.select { drawn?(it) }
      end

      # @return [String, nil]
      def path(item)
        @paths.fetch(item) { @paths[item] = resolve(item.path) }
      end

      # The module's `landing:`, or the first item its side menu draws that opens in place: the
      # switcher, like the palette, navigates in the same tab.
      #
      # @return [String, nil]
      def landing(app_module)
        @landings.fetch(app_module) do
          @landings[app_module] =
            if app_module.landing
              resolve(app_module.landing)
            else
              first = first_drawn_item(app_module)
              first && path(first)
            end
        end
      end

      # @param node [Item, Group]
      # @return [Object, nil]
      def badge(node)
        node.badge.is_a?(Proc) ? context.instance_exec(&node.badge) : node.badge
      end

      # True for the item the location names, false for the rest while it is drawn, and nil when
      # no drawn item is placed — then the side menu's own path matching decides.
      #
      # @return [Boolean, nil]
      def active(item)
        winner = location&.item
        return unless winner&.menu?

        item.equal?(winner)
      end

      # @return [Node, nil] the node, if this person may open it
      def find(key)
        node = navigation.find(key)
        node if node && offered?(node)
      end

      # Every item this person may open that the palette can offer: drawn or `menu: false`, with a
      # path, and not opening elsewhere (the palette navigates in place).
      #
      # @return [Array<Hash>] `title:`, `meta:`, `icon:`, `href:`, `search:` for `Bali::Command`'s items
      def palette_entries
        palette_pages.values
      end

      # The palette entries of the items declared `frequent: true`, in declaration order.
      #
      # @return [Array<Hash>]
      def frequent_entries
        palette_pages.filter_map { |item, entry| entry if item.frequent? }
      end

      private

      attr_reader :context

      # @return [Boolean]
      def offered?(node)
        visible?(node) && node.ancestors.all? { visible?(it) }
      end

      # The path the location is computed for: the navigation's `current_controller_path`, or the
      # context's `controller_path`.
      #
      # @return [String]
      def controller_path
        @controller_path ||= begin
          resolver = navigation.controller_path_resolver
          (resolver ? context.instance_exec(&resolver) : context.controller_path).to_s
        end
      end

      def visible?(node)
        return @visible[node] if @visible.key?(node)

        @visible[node] = (gate_open?(node) && (node.item? || node.children.any? { drawn?(it) })) ? true : false
      end

      def drawn?(node)
        visible?(node) && (!node.item? || node.menu?)
      end

      # Memoized through `visible?`, its only caller: each gate runs once per menu.
      def gate_open?(node)
        gate = node.gate
        case gate
        when nil then true
        when Proc then context.instance_exec(&gate)
        else context.instance_exec(gate, &navigation.authorizer)
        end
      end

      def resolve(value)
        case value
        when Symbol then context.main_app.public_send(value)
        when Proc then context.instance_exec(&value)
        else value
        end
      end

      def by_query(claims)
        scored = claims.filter_map { |claim| (score = query_score(claim.node)) && [ claim, score ] }
        return claims if scored.empty?

        top = scored.map(&:last).max
        scored.select { it.last == top }.map(&:first)
      end

      # The number of parameters of the item's path query the request carries with the same
      # value; nil when one is missing or differs. A node without a query scores zero.
      def query_score(node)
        return 0 unless node&.item?

        query = URI.parse(path(node).to_s).query
        return 0 if query.blank?

        wanted = Rack::Utils.parse_query(query)
        wanted.size if wanted.all? { |key, value| request_query[key].to_s == value.to_s }
      rescue URI::InvalidURIError
        nil
      end

      def request_query
        @request_query ||= context.request.query_parameters.stringify_keys
      end

      def first_drawn_item(node)
        node.children.each do |child|
          next unless drawn?(child)

          found = child.item? ? (child if !child.target && path(child)) : first_drawn_item(child)
          return found if found
        end
        nil
      end

      def palette_pages
        @palette_pages ||= {}.compare_by_identity.tap do |pages|
          palette_roots.flat_map { |root| offered_items(root) }.each do |item|
            href = path(item) unless item.target
            next unless href

            pages[item] = { title: item.title, meta: palette_meta(item), icon: item.icon, href: href,
                            search: search_text(item) }
          end
        end
      end

      def palette_roots
        navigation.app_modules? ? app_modules : navigation.roots.select { offered?(it) }
      end

      def offered_items(node)
        node.children.select { visible?(it) }.flat_map { |child| child.item? ? [ child ] : offered_items(child) }
      end

      def palette_meta(item)
        (item.app_module || item.section).title
      end

      def search_text(item)
        keywords = item.keywords.is_a?(Proc) ? context.instance_exec(&item.keywords) : item.keywords
        group = item.parent if item.parent.is_a?(Group)
        [ item.title, group&.title, item.section&.title, item.app_module&.title, item.hint, *Array(keywords) ]
          .compact.uniq.join(" ")
      end
    end
  end
end
