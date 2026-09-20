# frozen_string_literal: true

module Bali
  module Topbar
    module ToolsMenu
      # A tool in the topbar menu.
      #
      # It answers two questions and no more: "does it exist in this environment?" and
      # "where does it point?". Who may see it is NOT its business — the host decides that
      # and passes the list already filtered (see the spec: it is what lets apps with
      # different authorization models use the same component).
      #
      # The `context` is RECEIVED, not looked up. It is the view context the component is
      # already rendering in, not `Rails.application.routes.url_helpers`. That avoids global
      # state and is tested with a double, without mounting routes.
      #
      # `route_helper` is resolved against the context, and if the context does not know it,
      # against its `main_app` — the fallback that keeps the menu alive on an engine screen
      # rendered with the host's layout (see `resolver`). What CANNOT be expressed is a
      # helper of ANOTHER engine (`bali_auth_admin.bar_path`): only the host has a proxy of
      # its own. That is why `initialize` demands that `route_helper` end in `_path` or
      # `_url` — it closes the case where someone passes the bare proxy (`:main_app`) and
      # `href` would leak the `RoutesProxy` itself into the attribute.
      Tool = Data.define(:key, :icon, :route_helper, :url, :in_app, :name, :meta) do
        def initialize(key:, icon:, route_helper: nil, url: nil, in_app: false, name: nil, meta: {})
          if route_helper && url
            raise ArgumentError,
                  "`route_helper:` and `url:` are exclusive: a tool is either mounted in the " \
                  "host app (route_helper) or lives elsewhere (url)."
          end

          if route_helper.nil? && url.nil?
            raise ArgumentError,
                  "a tool needs `route_helper:` (mounted in the host app) or `url:` (a lambda " \
                  "returning an external URL)."
          end

          if route_helper && !route_helper.to_s.end_with?("_path", "_url")
            raise ArgumentError,
                  "`route_helper:` has to be a route helper name ending in `_path` or " \
                  "`_url` (e.g. `:mission_control_jobs_path`). `#{route_helper.inspect}` " \
                  "looks like an engine proxy (`main_app`, `bali_auth_admin`), not a " \
                  "helper — the proxy itself responds to `respond_to?`, and `href` would " \
                  "return it verbatim instead of a URL."
          end

          super
        end

        # `route_helper` present: it exists if the context KNOWS HOW TO RESOLVE that helper
        # — that is how a tool turns itself on as soon as its route is mounted, without
        # copying the host's environment condition here.
        #
        # WATCH OUT for what this does NOT cover: a `constraints` on the route does not stop
        # the helper from existing. The question is "is it mounted?", not "does this user
        # pass?".
        def available?(context)
          route_helper ? !resolver(context).nil? : href(context).present?
        end

        def href(context)
          return url.call unless route_helper

          resolver(context)&.public_send(route_helper)
        end

        # Who knows how to resolve this helper: the context itself, or the context's
        # `main_app`.
        #
        # The second case is NOT decoration. An engine that renders its screens with the
        # host's layout —`BaliAuth.configuration.admin_layout = "application"`, which is how
        # the group's four apps serve `/admin/auth/...`— renders that layout, and this menu
        # with it, against the ENGINE's view context. There the host's helpers do not exist:
        # measured in gobierno-corporativo on `BaliAuth::Admin::RolesController`,
        # `respond_to?(:mission_control_jobs_path)` is `false` and
        # `main_app.mission_control_jobs_path` returns `/admin/jobs`.
        #
        # Without this fallback, migrating to this component silently TURNS OFF the tools
        # mounted on exactly those screens —the external ones survive, because their `url:`
        # does not consult routes—, and the menu is left half empty with no error to give it
        # away. The host already writes `main_app.` in the rest of that same topbar for this
        # reason.
        #
        # The direct context wins: on a host screen `main_app` is never consulted, so this
        # cannot change what already resolved. And the router's rule is kept whole —
        # `RoutesProxy#respond_to?` answers `false` for a helper that does not exist, just
        # like the context.
        private def resolver(context)
          return context if context.respond_to?(route_helper)

          proxy = context.main_app if context.respond_to?(:main_app)
          proxy if proxy.respond_to?(route_helper)
        end

        def in_app? = in_app

        def new_tab? = !in_app?
      end
    end
  end
end
