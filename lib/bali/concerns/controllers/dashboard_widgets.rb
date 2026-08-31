# frozen_string_literal: true

module Bali
  module Concerns
    module Controllers
      # A WHOLE DASHBOARD FROM ONE CONTROLLER. Include this, name your catalog,
      # say who owns the rows, and the six surfaces a customisable dashboard
      # needs are wired: the grid, the picker, and the four writes behind them.
      #
      #   class DashboardController < ApplicationController
      #     include Bali::Concerns::Controllers::DashboardWidgets
      #
      #     dashboard_widgets catalog: Widgets::ALL
      #
      #     private
      #
      #     def widget_owner = current_user
      #   end
      #
      #   # config/routes.rb
      #   resource :dashboard, only: %i[show create edit update destroy] do
      #     patch :arrange
      #     get :refresh
      #   end
      #
      # | action    | verb + path             | what it is                        |
      # |-----------|-------------------------|-----------------------------------|
      # | `show`    | `GET    /dashboard`     | the grid                          |
      # | `edit`    | `GET    /dashboard/edit`| the picker                        |
      # | `update`  | `PATCH  /dashboard`     | save the picker                   |
      # | `arrange` | `PATCH  /dashboard/arrange` | drag, resize, remove          |
      # | `destroy` | `DELETE /dashboard`     | restore defaults                  |
      # | `create`  | `POST   /dashboard`     | adopt the defaults, then edit     |
      # | `refresh` | `GET    /dashboard/refresh` | re-render named cards         |
      #
      # THE HUMAN PAIR IS PLAIN REST — `edit` renders the form, `update` saves
      # it. `arrange` is verb-named and off to the side because it is not a
      # form: it is what Bali's own grid JS PATCHes on every drag, answering
      # `204` or a Turbo Stream for one resized card. Calling it `update` is
      # what forces a host into a second controller, since the picker needs
      # that name.
      #
      # ---- the seams ------------------------------------------------------
      #
      #   * `widget_owner`   — REQUIRED. Whose rows these are, usually
      #     `current_user`. A controller that forgets fails loudly with its own
      #     name rather than a bare NoMethodError.
      #   * `widget_actor`   — who `authorized?` is asked about. Defaults to
      #     `widget_owner`, and is separate because they genuinely differ: an
      #     app authorising through Pundit gates on `pundit_user` while the rows
      #     belong to `current_user`.
      #   * `widget_context` — the scoping string, for a tenant. Defaults to
      #     `""`. Unrelated to `Bali::Widget::Base#context`, which is the actor.
      #
      # ---- the views ------------------------------------------------------
      #
      # `show` and `edit` render Bali's own templates, so a host that writes no
      # ERB still gets a working dashboard. Define `app/views/<controller>/show
      # .html.erb` (or `edit`) and yours wins — `_prefixes` puts the engine's
      # behind the controller's own.
      module DashboardWidgets
        extend ActiveSupport::Concern

        included do
          class_attribute :widget_catalog, :widget_dashboard_key, instance_writer: false

          # Read by the templates. A controller assigning `@store = widget_store`
          # so a template can reach the memo is a self-assignment that looks
          # redundant, gets deleted, and takes the page down with it.
          helper_method :widget_store, :widget_offering
        end

        class_methods do
          # `catalog` is widget CLASSES, and ITS ORDER IS THE DEFAULT DASHBOARD:
          # an owner with no stored rows sees the offering in exactly this
          # sequence. That is why it is authored rather than discovered —
          # discovery gives alphabetical and nothing else.
          #
          # It belongs to the DASHBOARD, not the app: two dashboards are two
          # orderings, which may overlap.
          #
          # A proc or a symbol works too, resolved per request against the
          # controller, for a catalog not knowable at class-definition time:
          #
          #   dashboard_widgets catalog: -> { Widgets::TODAY + current_tenant.extras }
          #
          # Reach for it only when you need it — an array is greppable and a proc
          # is not, and per-owner differences are usually `authorized?`'s job.
          def dashboard_widgets(catalog:, dashboard_key: nil)
            self.widget_catalog       = catalog
            self.widget_dashboard_key = (dashboard_key || controller_path).to_s
          end

          # Bali's templates, behind the controller's own. Rails memoises
          # `_prefixes`, so this is computed once per class like the original.
          def _prefixes
            @_widget_prefixes ||= super + %w[bali/dashboard_widgets]
          end
        end

        # ---- the surfaces ---------------------------------------------------

        def show; end

        def edit; end

        # The picker submits membership, not an arrangement.
        def update
          widget_store.choose(submitted_widgets)

          redirect_to widget_dashboard_path, notice: t("bali_view.widgets.notices.saved")
        end

        # THE GRID'S ENDPOINT. `204` for a gesture that changed position — the
        # browser already moved the card, and re-rendering would replace the
        # nodes SortableJS just placed — and a Turbo Stream for one that changed
        # SHAPE, since a card's interior is server-rendered and a grown card
        # would otherwise keep its smaller body.
        def arrange
          widget_store.arrange(submitted_layout)

          resized = resized_placement
          return head :no_content unless resized

          render turbo_stream: turbo_stream.replace(
            Bali::Widget::Component.dom_id(resized.key),
            renderable: Bali::Widget::Component.new(resized.widget, size: resized.size)
          )
        end

        # ONE URL FOR EVERY WIDGET. The card sends its own key, this finds it and
        # streams that card back — so a widget that declares `refresh_every` needs
        # no route, no action and no controller of its own.
        #
        # `keys` PLURAL even though a card sends one: every request rebuilds the
        # whole offering to resolve a key, which is the security boundary and not
        # avoidable, so batching several tiles into one tick stays a JS-only
        # change.
        #
        # A key outside the offering finds nothing and is simply absent from the
        # response — the same silent drop as everywhere else.
        def refresh
          render turbo_stream: placements_for(params[:keys]).map { |placement|
            turbo_stream.replace(
              Bali::Widget::Component.dom_id(placement.key),
              renderable: Bali::Widget::Component.new(placement.widget, size: placement.size,
                                                      refresh_url: url_for(action: :refresh))
            )
          }
        end

        # A "Personalise" button, for someone who has never customised. `adopt`
        # decides whether there is anything to do from inside its own lock.
        #
        # Redirects rather than `204`, because this one DOES change what renders:
        # the grid goes from defaults-by-absence to the same widgets stored
        # explicitly, and comes back in edit mode.
        def create
          widget_store.adopt

          redirect_to widget_dashboard_path(editing: 1)
        end

        # `see_other` per the Rails destroy convention: inert while `button_to`
        # posts with `_method`, load-bearing the moment it does not — a real
        # DELETE survives a 302 and would be re-issued against the dashboard.
        def destroy
          widget_store.reset

          redirect_to widget_dashboard_path, notice: t("bali_view.widgets.notices.reset"),
                                             status: :see_other
        end

        private

        # THE GATE, memoised. Un-loaded instances, so this costs only whatever
        # the host's `authorized?` bodies cost and never a widget query.
        def widget_offering
          @widget_offering ||= Bali::Widget.authorized_for(
            widget_catalog_classes.map { |klass| klass.new(widget_actor) }
          )
        end

        # `instance_exec` rather than `call`, so a proc catalog reads like the
        # rest of a controller.
        def widget_catalog_classes
          case widget_catalog
          when Proc   then Array(instance_exec(&widget_catalog))
          when Symbol then Array(send(widget_catalog))
          else Array(widget_catalog)
          end
        end

        def widget_store
          @widget_store ||= Bali::DashboardWidget::Store.new(
            owner: widget_owner, context: widget_context,
            dashboard_key: widget_dashboard_key, offering: widget_offering
          )
        end

        # ---- seams -----------------------------------------------------------

        def widget_owner
          raise NotImplementedError, "#{self.class.name} must define #widget_owner"
        end

        def widget_actor = widget_owner

        def widget_context = ""

        # `url_for` rather than a named helper, so this works whatever a host
        # called its route.
        def widget_dashboard_path(**options) = url_for(action: :show, **options)

        # ---- params ----------------------------------------------------------

        # JUST THE WIRE FORMAT — `Store#arrange` resolves these against the
        # offering itself.
        #
        # The `blank?` guard runs BEFORE `expect`: `expect` raises
        # `ParameterMissing` (a 400) on an omitted `widgets` key AND on an empty
        # `widgets: []`, and only one of those is an error. Removing the last card
        # submits nothing at all, and that is the RESET gesture.
        #
        # `expect` rather than `params[:widgets]` for the case the guard misses:
        # `?widgets=lol` is a String, and indexing it raises `TypeError` — a 500
        # for a request that deserves a 400. Nothing is mass-assigned here, so the
        # SHAPE check is what earns the call.
        def submitted_layout
          return [] if params[:widgets].blank?

          params.expect(widgets: [ %i[key size] ])
        end

        # THE PICKER'S BOUNDARY. A submitted key becomes a widget only by being
        # found in the authorized offering; anything else is dropped silently, so
        # a role revoked between render and submit degrades rather than 422s.
        def submitted_widgets
          by_key = Bali::Widget.by_key(widget_offering)

          Array(params[:widget_keys]).filter_map { |key| by_key[key.to_s] }
        end

        # Looked up in the arrangement just written, so it comes back at its NEW
        # size. Nil for anything that is not a resize.
        def resized_placement
          key = params[:resized_key].presence
          return if key.nil?

          placements_for([ key ]).first
        end

        # PLACEMENTS, not widgets. A card has to come back at the size this owner
        # stored it at — rendering the bare widget would fall back to
        # `default_size` and silently un-resize every card it touched.
        #
        # Reads the arrangement, so it is also the boundary: a key that is not on
        # this owner's dashboard, or not in the offering, matches nothing.
        def placements_for(keys)
          wanted = Array(keys).map(&:to_s)
          return [] if wanted.empty?

          widget_store.widgets.select { |placement| wanted.include?(placement.key) }
        end
      end
    end
  end
end
