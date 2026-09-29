# frozen_string_literal: true

module Bali
  module DataTable
    class Component < ApplicationViewComponent
      include Bali::DataTable::ToolbarHref

      SUMMARY_POSITIONS = %i[top bottom].freeze

      # Priority drives TWO things at once, and that is why the scale cannot be renumbered
      # looking at only one of them: what SURVIVES in a narrow viewport (everything below
      # OVERFLOW_THRESHOLD collapses) and, WITHIN each group, the ORDER the controls are
      # painted in — the JS reorders each group by priority when expanding, so moving a
      # block in the template moves nothing in the browser.
      #
      # The order BETWEEN groups is fixed by the template (see #show_toolbar_left? and its
      # siblings), which is the only thing that lets the view switch survive everything and
      # still read last.
      #
      # The numbers descend in the same order the controls of the row are read in: that is
      # what keeps the reading order of the ⋯ identical to the toolbar's (see
      # `collapsibleItems` in the controller). `search` and `filters` are THE SAME node
      # (Bali::Filters paints the search input and the filters button together), hence a
      # single entry. Kept as a scale and not as an ordered list so that adding a second
      # threshold is a one-line change.
      OVERFLOW_PRIORITIES = {
        filters: 70,
        view_switch: 50,
        group_by: 40,
        column_selector: 35,
        saved_views: 30,
        filter_persistence: 25,
        toolbar_buttons: 10
      }.freeze

      # Collapses whatever sits BELOW the threshold. With a single breakpoint the scale
      # reduces to this one cut.
      OVERFLOW_THRESHOLD = 50

      attr_reader :pagy

      renders_one :custom_pagy_nav

      # Contextual selection bar: it REPLACES the toolbar row while there is a selection
      # and restores it on clear. The Stimulus controller lives on the DataTable CONTAINER
      # (see #container_attributes) and not on this slot: two nested `bulk-actions`
      # controllers split the targets between them and the bar would not see the rows.
      #
      # The block is NOT run here, unlike column_selector/view_switch: `with_action` is a
      # real ViewComponent slot, and reading a slot already forces the block to be evaluated
      # once (Slotable#__vc_get_slot calls `content`). Running it here as well executes it
      # TWICE and silently duplicates every action. The other two slots do not have the
      # problem because their `with_*` is a plain method over an array.
      #
      # @param options [Hash] Bali::BulkActions options (class:, data:)
      # @yield [bulk_actions] Block to declare the actions with `with_action`
      #
      # `**options` goes FIRST: what the component owns cannot be overridden by the host.
      # Splatted last, a `standalone: true` from the host nested a second controller and
      # silently broke the invariant this comment has just documented.
      #
      # `total_count:` and `filter_params:` go BEFORE the splat: they are a default derived
      # from the listing (the `pagy` and the `filter_form` this DataTable already has), not
      # a component invariant, so the host may override them — to narrow the offer to
      # another count, or to turn it off with `total_count: nil` on a listing where an
      # action over the whole result set makes no sense.
      renders_one :bulk_actions, ->(**options) do
        Bali::BulkActions::Component.new(
          total_count: bulk_actions_total_count,
          filter_params: Bali::Filters::ActiveFilterParams.for_filter_form(@filter_form),
          **options, variant: :toolbar, standalone: false
        )
      end

      # Filters panel using Filters component.
      #
      # When a filter_form is provided to DataTable, everything is automatically
      # populated from the form: available_attributes, filter_groups, and search config.
      #
      # @param available_attributes [Array<Hash>] Filterable attributes
      #   (auto-populated from filter_form if not provided)
      # @param filter_groups [Array<Hash>] Initial filter state
      #   (auto-populated from filter_form if not provided)
      # @param search [Hash] Quick search configuration
      #   (auto-populated from filter_form if not provided)
      #   - :fields [Array<Symbol>] Fields to search (e.g., [:name, :description])
      #   - :value [String] Current search value from URL params
      #   - :placeholder [String] Placeholder text for search input
      # @param apply_mode [Symbol] :batch (default) or :live
      # @param popover [Boolean] Show filters in popover (default: true)
      #
      # @example Minimal usage (everything auto-configured from FilterForm)
      #   data_table.with_filters_panel
      #
      # @example Override search placeholder
      #   data_table.with_filters_panel(search: { placeholder: 'Search movies...' })
      #
      # @example Full control
      #   data_table.with_filters_panel(
      #     available_attributes: [{ key: :name, type: :text }, ...],
      #     filter_groups: @filter_form.filter_groups,
      #     search: { fields: [:name], value: '...', placeholder: '...' }
      #   )
      renders_one :filters_panel, ->(available_attributes: nil, search: nil, **options) do
        # Auto-populate from filter_form if not explicitly provided
        resolved_attributes = available_attributes || @filter_form&.available_attributes || []

        # Auto-populate filter_groups from filter_form unless explicitly provided
        if !options.key?(:filter_groups) && @filter_form.respond_to?(:filter_groups)
          options[:filter_groups] = @filter_form&.filter_groups
        end

        # Auto-populate storage_id from filter_form unless explicitly provided
        options[:storage_id] ||= @filter_form&.storage_id if @filter_form.respond_to?(:storage_id)

        # Auto-populate persist_enabled from filter_form unless explicitly provided
        if !options.key?(:persist_enabled) && @filter_form.respond_to?(:persist_enabled?)
          options[:persist_enabled] = @filter_form.persist_enabled?
        end

        # Auto-populate the APPLIED combinator (nil when the state carried no `q[m]`), so the
        # panel re-emits what the user chose instead of its own `:and` default — re-emitting
        # the default flipped an applied OR to AND on the next round-trip.
        if !options.key?(:combinator) && @filter_form.respond_to?(:applied_combinator)
          options[:combinator] = @filter_form.applied_combinator
        end

        # Preserve the listing state (grouping + display mode) across the GET filter submit
        # (round-trip). Explicit preserved_params MERGE with it instead of replacing it: a
        # host preserving its own params should not silently drop the grouping on every
        # filter/search submit.
        options[:preserved_params] = preserved_state_params.merge(options[:preserved_params] || {})

        # The marker is painted ONCE, and as a toolbar control of its own (see
        # #filter_persistence_control): two `filter-persistence` controllers over the same
        # storage_id clobber each other's localStorage and cookie. The panel still receives
        # `persist_enabled` — that is where its "Auto-guardado" legend comes from.
        #
        # Assignment and not `||=`: the `**options` splat goes LAST in the constructor, so a
        # `persistence_toggle: true` from the host would win and nest the second controller.
        capture_persistence(options[:storage_id], options[:persist_enabled])
        options[:persistence_toggle] = false

        Filters::Component.new(
          url: @url,
          available_attributes: resolved_attributes,
          search: resolved_search_config(search),
          **options
        )
      end

      # Simple inline filters (alternative to filters_panel).
      # Use this for CRUD views that only need 2-4 dropdown filters without
      # AND/OR groupings, popovers, or badges.
      #
      # Mutually exclusive with filters_panel - use one or the other.
      #
      # @param filters [Array<Hash>] Filter definitions (auto-populated from filter_form)
      #   Each filter hash should have: :attribute, :collection, :blank, :label, :value, :default
      # @param preserved_params [Hash] Host params that the row's GET submit carries along
      #   as hidden fields, merged over the listing state (`group_by`, `view`) — same
      #   contract as in `filters_panel` (#1056).
      #
      # @example Minimal (auto-configured from FilterForm)
      #   data_table.with_simple_filters
      #
      # @example With explicit filters
      #   data_table.with_simple_filters(filters: [
      #     { attribute: :status, collection: [["Active", "active"]], blank: "All" }
      #   ])
      renders_one :simple_filters, ->(filters: nil, search: nil, storage_id: nil,
                                      persist_enabled: nil, preserved_params: {}) do
        resolved_filters = filters || @filter_form&.simple_filters_config || []
        resolved_search = resolved_search_config(search)
        filters_active = @filter_form&.simple_filters_active? || false
        search_active = resolved_search&.dig(:value).present?

        # Auto-populate storage_id from filter_form unless explicitly provided
        storage_id ||= @filter_form&.storage_id if @filter_form.respond_to?(:storage_id)

        # Auto-populate persist_enabled from filter_form unless explicitly provided
        if persist_enabled.nil? && @filter_form.respond_to?(:persist_enabled?)
          persist_enabled = @filter_form.persist_enabled?
        end

        # Same reason as in `filters_panel`: the marker comes from the form and the toolbar
        # paints it.
        capture_persistence(storage_id, persist_enabled)

        SimpleFilters::Component.new(
          url: @url,
          filters: resolved_filters,
          show_clear: filters_active || search_active,
          search: resolved_search,
          storage_id: storage_id,
          persist_enabled: persist_enabled || false,
          persistence_toggle: false,
          # Same semantics and precedence as in `filters_panel`: explicit params MERGE with
          # the listing state instead of replacing it (#1056). Replacing silently loses any
          # host param of its own on every GET submit of the row.
          preserved_params: preserved_state_params.merge(preserved_params || {})
        )
      end

      renders_one :summary

      class DuplicateContent < StandardError; end

      DUPLICATE_CONTENT_MESSAGE = "DataTable renders ONE content slot " \
        "(with_table / with_grid / with_content). To alternate between modes, pick " \
        "which one you declare with an if on display_mode."

      VIEW_PARAM_MISMATCH_MESSAGE = "The DataTable reads the display mode from `%s` and the " \
        "FilterForm from `%s`. Out of sync, grouping is suspended looking at a param the " \
        "view switch never writes (or keeps being applied in cards). Pass the same " \
        "`view_param:` to both."

      DISPLAY_MODE_MISMATCH_MESSAGE = "This listing renders `%s`, which is not among the " \
        "modes that apply grouping (%s), but its FilterForm never saw a mode: without " \
        "`?view=` in the URL it assumes grouping applies and orders the rows by the group " \
        "with nothing on screen explaining it. Pass the mode to the form: " \
        "`Bali::FilterForm.new(..., display_mode: params[:view] || :%s)`."

      # Content band. The SURFACE is decided by the slot, not by the host: `with_table`
      # brings one (a table needs a background of its own), `with_grid` does not (the cards
      # ALREADY are the surface). The slot cannot be named `content` —ViewComponent reserves
      # it— hence the internal name and the public `with_content` alias.
      #
      # @param surface [Boolean] Wrap the content in Bali::Card (default: true)
      # @param scroll [Boolean] Wrap it in the horizontal scroll wrapper (default: false)
      # @param card_options [Hash] Bali::Card options (style:, class:, shadow:, body_class:)
      renders_one :content_band, ->(surface: true, scroll: false, **card_options, &block) do
        body = if block.nil?
                 "".html_safe
        elsif scroll
                 tag.div(class: content_scroll_classes, &block)
        else
                 block.call
        end

        # ALWAYS return a String: on nil ViewComponent silently drops the content, and
        # returning the Card would hand it the original block, without the scroll wrapper.
        surface ? render(Bali::Card::Component.new(**card_options)) { body } : body
      end

      # Slot for right-aligned toolbar buttons (column selector, export, etc.)
      renders_many :toolbar_buttons

      # Built-in column selector with declarative API
      # @param persist [Boolean] Save visibility per device (localStorage).
      #   Ignored when the listing has no stable id (see #id).
      # @param button_label [String] Label for the dropdown button (i18n default)
      # @param button_icon [String] Icon name
      # @yield [column_selector] Block to define columns
      renders_one :column_selector, ->(persist: true, **opts, &block) do
        # `**opts` first: the listing identity is resolved by the DataTable, and overriding
        # it from the host pointed the selector at a container other than the saved views'.
        component = ColumnSelector::Component.new(**opts, listing_id: id, persist: persist && stable_id?)
        block&.call(component)
        # An applied saved view WINS: its visible columns override the defaults declared
        # per column, and the selector marks server_state so the JS does not restore
        # localStorage on top of the view's state.
        if @filter_form.respond_to?(:saved_view_columns) && (view_columns = @filter_form.saved_view_columns)
          component.apply_visible_columns(view_columns)
        end
        component
      end

      # "Vistas" dropdown (B2): NAMED saved filter combinations. It only paints when the
      # filter_form brings a `saved_views_store`. `url:` is the RESTful base for
      # create/rename/delete (POST url, PATCH/DELETE url/:id); when omitted it points at
      # the ENGINE's own routes (which requires mounting it and the form having a
      # `storage_id` — without storage_id there is no default URL and the dropdown does not
      # paint). The listing identity (see #id) connects with the column selector to save the
      # visible columns inside the view; `default_views:` are static {name:, url:} shortcuts
      # ("Sugeridas").
      renders_one :saved_views, ->(url: nil, default_views: nil) do
        SavedViews::Component.new(filter_form: @filter_form, url: url || default_saved_views_url,
                                  base_url: saved_views_base_url, listing_id: id,
                                  default_views: default_views)
      end

      # Segmented view control (table / cards / whatever the host defines). Unlike
      # Bali::ViewSwitch, `href:` is NOT passed here: each view declares its `value:` and the
      # DataTable builds the link preserving the query string. `href:` is still accepted per
      # view for a mode that lives on another route.
      #
      # @param aria_label [String] Accessible label for the group (i18n default)
      # @param options [Hash] Bali::ViewSwitch options (size:, icon_only:, class:)
      # @yield [view_switch] Block to declare the views with `with_view`
      renders_one :view_switch, ->(aria_label: nil, **options, &block) do
        # The switch does NOT collapse into the ⋯ (priority 50 = threshold): it SHRINKS.
        # `:responsive` hides the text below sm keeping title/aria-label, so the button is
        # never left without an accessible name — which is what hiding the label by hand
        # would do.
        options[:icon_only] = :responsive unless options.key?(:icon_only)

        # `**options` first: the URL, the param and the current mode are resolved by the
        # DataTable — overriding them from the host gave links pointing at one param and
        # hidden fields at another.
        component = ViewSwitchControl::Component.new(
          **options,
          url: @url,
          current_params: request_query_params,
          param: @view_param,
          current: requested_display_mode,
          aria_label: aria_label
        )
        block&.call(component)
        # Gating display_mode needs the views ALREADY declared, and that only happens
        # after running the host's block (see #display_mode).
        @view_switch_control = component
        component
      end

      # @param url [String] Base URL for filtering/sorting links. It is also the base for
      #   the page links when the Pagy cannot build its own (see #pagination_url)
      # @param filter_form [Bali::FilterForm] Optional filter form for Ransack integration
      # @param pagy [Pagy] Optional Pagy object for pagination
      # @param show_summary [Boolean] Show summary (default: true when pagy present)
      # @param summary_position [Symbol] :bottom (default) or :top
      # @param item_name [String, Symbol, Hash] Name for items in summary. A Symbol is an
      #   i18n key resolved with `count:` (full CLDR plurals); a Hash picks `one:`/`other:`
      #   by count; a String is used verbatim, invariant with the count (i18n default)
      # @param table_class [String] CSS class for the content scroll wrapper
      # @param display_mode [Symbol] Display mode requested by the host (typically
      #   `params[:view]`). It does NOT pick a slot (there is only one): the host decides
      #   what content it declares, reading the ALREADY validated value in #display_mode.
      # @param view_param [Symbol] URL param carrying the view (default :view)
      # @param id [String] Listing identity. It is at once the container id, the
      #   querySelector target of the column selector (`#<id> table`) and the localStorage
      #   key of its columns: ONE name for everything the listing persists.
      def initialize(url:, filter_form: nil, pagy: nil, **options)
        @filter_form = filter_form
        @url = url
        @pagy = pagy
        @show_summary = options.fetch(:show_summary) { pagy.present? }
        @summary_position = validate_summary_position(options[:summary_position])
        @item_name = options[:item_name]
        @table_wrapper_class = options[:table_class]
        # `.to_s` first: this usually arrives straight from `params[:view]`, and a nested
        # param (`?view[]=x`) does not respond to `to_sym`. The value is validated later
        # against the declared views (see #display_mode); here it is only normalized
        # without blowing up.
        @display_mode = (options[:display_mode].to_s.presence || "table").to_sym
        @view_param = (options[:view_param] || Bali::FilterForm::DEFAULT_VIEW_PARAM).to_sym
        # Only a host that DECLARED the mode has a `view` to preserve; the default is not
        # written into the URL of a listing that does not even have a view switch.
        @display_mode_declared = options[:display_mode].present?
        @content_declared = false
        @listing_id, @stable_id = resolve_listing_id(options[:id])
        validate_view_param!
      end

      # Display mode ALREADY validated against the declared views: an unknown `?view=`
      # falls back to the first view instead of leaving the content empty (same boundary as
      # FilterForm#resolve_group_by). The host reads it inside the block to choose what
      # content it declares — which is why it is resolved late and not in `initialize`: the
      # views are declared AFTER the component is built.
      def display_mode
        mode = @view_switch_control ? @view_switch_control.current_value : requested_display_mode
        validate_display_mode!(mode)
        mode
      end

      # A single content band: `with_table`/`with_grid` are sugar over it. `display_mode`
      # NO LONGER picks between slots — the host decides what it renders.
      def with_content(surface: true, scroll: false, **options, &block)
        raise DuplicateContent, DUPLICATE_CONTENT_MESSAGE if @content_declared

        @content_declared = true
        with_content_band(surface: surface, scroll: scroll, **options, &block)
      end

      def with_table(**options, &block)
        with_content(surface: true, scroll: true, **options, &block)
      end

      def with_grid(**options, &block)
        with_content(surface: false, **options, &block)
      end

      def content_scroll_classes
        @table_wrapper_class || "overflow-x-auto"
      end

      # `min-h-8` is the height of a daisyUI `sm` control, which is the height this row
      # already had from its content. It is declared EXPLICITLY because the contextual
      # selection row replaces it in this same space
      # (`BulkActions::Component::TOOLBAR_MIN_HEIGHT`): with the height as an accident of
      # the content, any change there reintroduces the layout jump.
      #
      # `items-end` and not `items-center`: `SimpleFilters` puts the label ABOVE each
      # control, so its block measures twice its single-line neighbours and wraps onto two
      # lines when the row gets tight. Centred, everything sharing the row with it aligns
      # against the centre of that block instead of against the line of controls, which is
      # the one the eye uses: measured on /admin/studios at 1900px, the ⋯ sat at y=226 and
      # the Filter button — which lives on the last line of that block — at y=264, 38px
      # below. When no item is taller than the others the two alignments coincide.
      TOOLBAR_CLASSES = "flex items-end gap-2 sm:gap-4 min-h-8 mb-4"

      # The toolbar goes WITHOUT a surface: it is the SAME row in every display mode, and
      # the surface is brought by the content.
      def toolbar_classes
        TOOLBAR_CLASSES
      end

      def id
        @listing_id
      end

      # Does the id survive the next render? With the random hex it does not, and a key
      # that changes on every visit will never restore anything: per-device persistence
      # turns itself off instead of writing garbage nobody can read back.
      def stable_id?
        @stable_id
      end

      # The SAME sentence the footer paints, from the same place: the top summary and the
      # bottom one are the same count, and deriving them separately was what left two i18n
      # keys for a single sentence.
      def default_summary_text
        return "" unless @pagy

        pagy_adapter.summary(@item_name)
      end

      def show_summary_top?
        summary_position?(:top) && summarizable?
      end

      def show_summary_bottom?
        summary_position?(:bottom) && summarizable?
      end

      # The footer is built by `PaginationFooter`, which decides on its own whether it has
      # anything to draw; here it is only handed what this listing wants from it.
      #
      # `divider:` and not the spacing through `class:`: sending it that way left the
      # footer's `py-4` AND the listing's `pt-4` on the same element, which added 16px of
      # bottom padding the foot of the table never had. Tailwind resolves that pair by
      # stylesheet order, not by the order you write the classes in.
      def pagination_footer
        Bali::PaginationFooter::Component.new(
          pagy: @pagy,
          item_name: @item_name,
          show_summary: show_summary_bottom?,
          url: pagination_url,
          divider: true
        )
      end

      # ALREADY rendered content of a declarative control, or nil if the control decided
      # not to paint. Declaring the slot is NOT the same as painting: `with_saved_views` on
      # a form without a store leaves `render?` false, and looking only at the slot
      # predicate left an empty wrapper that on a phone ended up exposing a ⋯ opening an
      # empty menu — exactly what the #overflow_menu? gate exists to prevent.
      #
      # Memoized because the template reads it again (ViewComponent::Slot#to_s already
      # memoizes, but here the `nil` is cached as well).
      def control_content(key)
        @control_contents ||= {}
        return @control_contents[key] if @control_contents.key?(key)

        @control_contents[key] = (public_send(key).to_s.presence if public_send(:"#{key}?"))
      end

      def show_toolbar?
        declared_toolbar_controls.any?
      end

      # The container is what carries the selection controller: it has to wrap both the
      # contextual bar and the rows of the table.
      def container_attributes
        attrs = { id: id, class: "data-table-component" }
        bulk_actions? ? prepend_controller(attrs, "bulk-actions") : attrs
      end

      # The toolbar row carries the overflow controller, and is also marked so the
      # selection one can hide it while the contextual bar takes its place.
      def toolbar_attributes
        attrs = prepend_controller({ class: toolbar_classes }, "toolbar-overflow")
        # The server sets it and the controller removes it when its first `apply()` ends.
        # See RESERVED_CLASSES. Without JS the template's `<noscript>` uncovers it.
        attrs[SETTLING_ATTRIBUTE] = "" if overflow_menu?
        # The threshold is EMITTED: the ⋯ gate and the cut the JS applies are the same
        # number, and with two independent defaults moving it on one side left the other
        # painting a menu that never fills. The controller's default only covers hand-written
        # markup.
        prepend_values(attrs, "toolbar-overflow", threshold: OVERFLOW_THRESHOLD)
        return attrs unless bulk_actions?

        attrs[:data][:bulk_actions_target] = "toolbar"
        attrs
      end

      # Home container of a functional group: when expanding, each control returns to the
      # group it declares here. INVARIANT: a group may only have `item` children — the JS
      # reorders by appending by priority, and a child without a priority would end up
      # pushed to the end.
      def overflow_group_attributes(group, css_class:)
        {
          class: css_class,
          data: { toolbar_overflow_target: "group", toolbar_overflow_group: group }
        }
      end

      # Wrapper of a control: which group it returns to and with what priority (see
      # OVERFLOW_PRIORITIES). It is the node the JS MOVES, never copies.
      # A control that can collapse starts with its place RESERVED and undrawn, and the
      # controller reveals it when its first `apply()` ends. `visibility: hidden` and not
      # `display: none` on purpose: it keeps the box, so the measurement that decides the
      # collapse measures exactly the same as without this.
      #
      # What it avoids, measured on /admin/studios: the page paints at 260ms with the whole
      # row —which is the server's HTML, that is, the row NOT collapsed— and the controller
      # does not run until 1189ms, when a 4.8 MB bundle finishes executing. During that
      # second four controls were visible and then vanished all at once into the ⋯.
      # Reserved, what is seen is a gap that fills once.
      #
      # The arbitrary variant and not a rule in index.css: this way it lives in
      # @layer utilities, which is where a host can override it, and not in an unlayered
      # sheet whose header explains that it is unlayered for another reason.
      SETTLING_ATTRIBUTE = "data-toolbar-overflow-settling"
      RESERVED_CLASSES = "[[data-toolbar-overflow-settling]_&]:invisible"

      def overflow_item_attributes(key, group:, css_class: nil)
        priority = overflow_priority(key)

        {
          class: class_names(css_class, (RESERVED_CLASSES if priority < OVERFLOW_THRESHOLD)),
          data: {
            toolbar_overflow_target: "item",
            toolbar_overflow_group: group,
            toolbar_overflow_priority: priority
          }
        }
      end

      # The little bar is NOT a control: with no priority and not being an `item`,
      # `collapsibleItems` cannot see it and it never travels into the ⋯. It declares what
      # it separates BY NAME instead of looking at its DOM siblings: with adjacency,
      # inserting any node in between silently broke the decision. `max-sm:hidden` covers
      # the no-JS case — below the breakpoint nobody is left to its right to hold it up.
      def overflow_separator_attributes(*groups)
        {
          class: "shrink-0 max-sm:hidden",
          data: {
            toolbar_overflow_target: "separator",
            toolbar_overflow_separates: groups.join(" ")
          }
        }
      end

      # The ⋯ is not painted when there is nothing to collapse: without this, a listing
      # that only has search would show a button opening an empty menu.
      def overflow_menu?
        declared_toolbar_controls.any? { |key| overflow_priority(key) < OVERFLOW_THRESHOLD }
      end

      def overflow_priority(key)
        OVERFLOW_PRIORITIES.fetch(key)
      end

      def overflow_menu_label
        I18n.t("bali_view.data_table.toolbar_overflow.button_label")
      end

      # Whether the "Agrupar por" control should render — true when the filter form declares
      # any group_by attribute. Auto-rendered (no explicit slot).
      #
      # The control renders WHENEVER the form declares groupings. In a mode that does not
      # apply grouping it goes inert (see #group_by_disabled?) instead of disappearing:
      # hiding it moved the whole toolbar on a mode change and explained nothing. Whether
      # grouping applies is resolved by the FORM (FilterForm#group_by_applies?) and not by
      # the component — re-deriving it here was a second copy of the same rule, and the two
      # copies drift apart. `respond_to?` with a fallback to "applies": a foreign filter_form
      # cannot lose its control for not knowing the new API.
      def group_by_control?
        @filter_form.respond_to?(:group_by_options) && @filter_form.group_by_options.present?
      end

      def group_by_disabled?
        @filter_form.respond_to?(:group_by_applies?) && !@filter_form.group_by_applies?
      end

      # The auto-configured group_by control component.
      def group_by_control
        @group_by_control ||= GroupByControl::Component.new(
          url: @url,
          filter_form: @filter_form,
          current_params: request_query_params,
          disabled: group_by_disabled?
        )
      end

      # The marker remembers the state of the FILTERS: on its own, on a listing with no
      # filter control, it means nothing. It asks for the CONTENT and not for the slot
      # predicate because `SimpleFilters#render?` is false without filters or search —
      # declaring the slot is not the same as painting (see #control_content).
      def filter_persistence_control?
        @persistence_storage_id.present? &&
          (control_content(:filters_panel) || control_content(:simple_filters)).present?
      end

      def filter_persistence_control
        @filter_persistence_control ||= Bali::Filters::PersistenceToggle::Component.new(
          storage_id: @persistence_storage_id, enabled: @persistence_enabled
        )
      end

      # LEFT the listing state and how it is remembered; RIGHT how it looks. The display
      # mode does NOT travel inside a saved view (it is not in PAYLOAD_KEYS), and that is
      # why the view switch is the only thing left on the other side.
      #
      # First subgroup on the left: the CONTENT of the view — which rows and which columns.
      def show_toolbar_left?
        (declared_toolbar_controls & %i[filters group_by column_selector]).any?
      end

      # Second subgroup on the left: how that content is REMEMBERED.
      def show_toolbar_memory?
        (declared_toolbar_controls & %i[saved_views filter_persistence]).any?
      end

      # The host's buttons fall into none of the three buckets: a group of their own,
      # between what is remembered and the right edge. Put inside the right-hand group the
      # JS ordered them by priority (10 against 50) and they ended up AFTER the view switch,
      # which is the only thing that goes flush with the edge.
      def show_toolbar_host?
        declared_toolbar_controls.include?(:toolbar_buttons)
      end

      def show_toolbar_right?
        declared_toolbar_controls.include?(:view_switch)
      end

      # The little bar asserts something about both of its neighbours ("here ends what the
      # view contains and begins how it is remembered"): with only one side it would mark a
      # boundary against nothing. Below the breakpoint the JS hides it (see
      # #overflow_separator_attributes).
      def toolbar_separator?
        show_toolbar_left? && show_toolbar_memory?
      end

      private

      # The values are RESOLVED by the slot (they may come from the filter_form or be
      # explicit from the host), so they are captured there and not re-derived here:
      # re-deriving them from the filter_form left a host that passes `storage_id:` straight
      # to the slot without a marker.
      def capture_persistence(storage_id, enabled)
        @persistence_storage_id = storage_id.presence
        @persistence_enabled = !!enabled
        warn_unwired_persistence
      end

      # #999's safety net. The toggle is about to render (storage_id present),
      # so a form built without anyone reading the opt-in — or without a
      # context — is the silent failure mode: state saves into Rails.cache and
      # never restores, or every user restores everyone's. Development only —
      # in a host's test suite the warning is noise about an env that isn't
      # the one misconfigured (#1029) — once per storage_id per process;
      # `Bali::Filterable#filter_form` closes both halves and never trips this.
      def warn_unwired_persistence
        return unless Rails.env.development?
        return if @persistence_storage_id.blank? || @filter_form.nil?
        return unless @filter_form.respond_to?(:persistence_opt_in_read?)
        return if (self.class.persistence_warnings_issued ||= Set.new).include?(@persistence_storage_id)

        if !@filter_form.persistence_opt_in_read?
          self.class.persistence_warnings_issued << @persistence_storage_id
          Rails.logger.warn(
            "[Bali] DataTable \"#{@persistence_storage_id}\": the persistence toggle will " \
            "render, but the FilterForm was built without `persist_enabled:` — filters will " \
            "save and never restore. Build the form with Bali::Filterable#filter_form, or " \
            "pass persist_enabled: cookies[\"bali_persist_#{@persistence_storage_id}\"] == \"1\"."
          )
        elsif @filter_form.respond_to?(:context) && @filter_form.context.nil?
          self.class.persistence_warnings_issued << @persistence_storage_id
          Rails.logger.warn(
            "[Bali] DataTable \"#{@persistence_storage_id}\": persisted filters have no " \
            "`context:` — the cache key is one for the whole process, so every user restores " \
            "everyone's filters. Pass context: (Bali::Filterable#filter_form derives it from " \
            "Bali.filter_context), or context: nil explicitly stays silent only via the concern."
          )
        end
      end

      class << self
        attr_accessor :persistence_warnings_issued
      end

      # The `search:` hash both filter slots hand to their component: whatever the
      # FilterForm declares, with the slot's explicit options layered on top. The two
      # slots used to resolve it apart, from two different FilterForm builders, so a
      # listing that moved between them lost whichever keys the other shape lacked.
      def resolved_search_config(override)
        declared = @filter_form.search_config if @filter_form.respond_to?(:search_config)
        return declared || override.presence unless declared && override.present?

        declared.merge(override.to_h.symbolize_keys)
      end

      # Which control families PAINT something. This is the ONLY list: `overflow_menu?`,
      # `show_toolbar?` and each group's `show_toolbar_*` derive from here, so the ⋯ gate
      # cannot drift from what the JS collapses. It looks at the render, not at the slot
      # predicate (see #control_content).
      def declared_toolbar_controls
        @declared_toolbar_controls ||= begin
          controls = []
          controls << :filters if control_content(:filters_panel) || control_content(:simple_filters)
          controls << :filter_persistence if filter_persistence_control?
          controls << :group_by if group_by_control?
          controls << :view_switch if control_content(:view_switch)
          controls << :saved_views if control_content(:saved_views)
          controls << :column_selector if control_content(:column_selector)
          controls << :toolbar_buttons if toolbar_buttons?
          controls
        end
      end

      # [id, stable?]. `FilterForm#id` (scope.cache_key) does NOT work as an identity: it
      # brings a slash —'movies/query-abc'— that breaks the querySelector, and besides, two
      # listings over the same base scope land on the same value (that was the case for
      # /movies and /admin/movies, which ended up sharing the column memory).
      def resolve_listing_id(explicit)
        given = sanitize_listing_id(explicit) || sanitize_listing_id(form_storage_id)
        return [ given, true ] if given

        [ "data-table-#{SecureRandom.hex(4)}", false ]
      end

      # The SAME rule a host's `.turbo_stream.erb` has to be able to apply in order to aim
      # its `turbo_stream.replace`: it lives in ListingIdentity, public (see
      # ListingIdentity.for).
      def sanitize_listing_id(value)
        ListingIdentity.sanitize(value)
      end

      def form_storage_id
        @filter_form.storage_id if @filter_form.respond_to?(:storage_id)
      end

      # The requested mode, RAW: the one the host declared or, if it declared none, the one
      # the URL brings. Without the fallback, a host that builds the view switch and forgets
      # `display_mode:` gets links that change the URL and never change the view: the
      # component already has the query string in hand (it uses it to build those very
      # hrefs) and looking only at the kwarg was failing silently.
      #
      # Late and not in `initialize`: `helpers` does not exist yet before the render.
      def requested_display_mode
        return @display_mode if @display_mode_declared

        request_query_params[@view_param.to_s].to_s.presence&.to_sym
      end

      # Applying a saved view should not pull the user out of the mode they are looking at
      # the listing in: the view switch preserves `saved_view` on purpose and the reverse
      # direction has to be symmetric. ONLY the mode travels — carrying the whole query
      # string would make a `group_by` from the URL beat the one the view's payload brings
      # (see FilterForm#apply_saved_view_state).
      def saved_views_base_url
        view = view_preserved_params
        return @url if view.empty?

        "#{@url}#{@url.to_s.include?('?') ? '&' : '?'}#{view.to_query}"
      end

      # Default URL for saved view mutations: the ENGINE's own routes (mounted in the
      # host). The storage_id travels in the query string because the engine's create has
      # nowhere else to get it from.
      def default_saved_views_url
        return unless @filter_form.respond_to?(:storage_id) && @filter_form.storage_id.present?

        helpers.bali.saved_views_path(storage_id: @filter_form.storage_id)
      end

      # Listing state that has to survive a GET filter submit. The view switch links merge
      # the whole query string, but a filter submit rebuilds it from `url:` —which the host
      # passes WITHOUT a query string— so the grouping and the display mode have to travel
      # as hidden fields or filtering while in cards sends the user back to the table.
      def preserved_state_params
        group_by_preserved_params.merge(view_preserved_params).merge(saved_view_origin_params)
      end

      # The ORIGIN travels; `saved_view` does not (it stays in Filters' EXCLUDED_PARAMS,
      # because it APPLIES). Without this, changing a filter over an applied view turned it
      # anonymous and the dropdown could only offer to save another one.
      def saved_view_origin_params
        origin = @filter_form.try(:saved_view_origin_id)
        origin.present? ? { "view_origin" => origin.to_s } : {}
      end

      # The RAW mode, not the gated one: the views are declared after the filters panel
      # slot is built, so the gating cannot be resolved here yet. An unknown value is
      # harmless — the next request gates it again.
      def view_preserved_params
        mode = requested_display_mode
        mode.present? ? { @view_param.to_s => mode.to_s } : {}
      end

      # group_by param to preserve as a hidden field on GET filter forms, so
      # applying filters/search does not drop an active grouping.
      #
      # `group_by_active?` (STATE) and NOT `group_by_applied?` (APPLICATION) on purpose: in
      # cards the grouping is suspended but the param MUST keep travelling — otherwise
      # searching while in cards erases it and going back to the table no longer finds it.
      #
      # WHAT travels is the form's call — three answers since #1156, not two. An empty value
      # is dropped by `hidden_field` itself, so where a default is declared "no grouping"
      # travels named. See FilterForm#group_by_preserved_value.
      def group_by_preserved_params
        return legacy_group_by_preserved_params unless @filter_form.respond_to?(:group_by_preserved_value)

        value = @filter_form.group_by_preserved_value
        value.nil? ? {} : { "group_by" => value }
      end

      # A form that is not a Bali::FilterForm — the DataTable accepts any object answering
      # the slice of the contract it uses — keeps the old behaviour.
      def legacy_group_by_preserved_params
        return {} unless @filter_form.respond_to?(:group_by_active?) && @filter_form.group_by_active?

        { "group_by" => @filter_form.group_by.to_s }
      end

      # Fails early: with the two params out of sync there is NOTHING visible to give it
      # away — the table looks the same and the suspension decides the other way round. It
      # only matters if the listing declares grouping; without it the display mode changes
      # no decision.
      def validate_view_param!
        return unless @filter_form.respond_to?(:view_param) &&
                      @filter_form.respond_to?(:group_by_enabled?) &&
                      @filter_form.group_by_enabled? &&
                      @filter_form.view_param != @view_param

        raise ArgumentError,
              format(VIEW_PARAM_MISMATCH_MESSAGE, @view_param, @filter_form.view_param)
      end

      # The mode is derived TWICE —the DataTable resolves it against the declared views,
      # the form reads it from the URL— and without `?view=` the two derivations say
      # different things: the listing paints the first declared view and the form, seeing
      # nil, assumes grouping applies. With cards declared first that is grouping running
      # over cards, which is exactly what the suspension exists to prevent.
      #
      # It is validated at the moment the mode is CONSUMED (the host calls #display_mode to
      # choose what content it declares) because the views are declared after the component
      # is built. Only when the form has no mode of its own: with an unknown `?view=` —which
      # a user can type— the form suspends and the listing falls back to the first view, and
      # that is a known limit, not a broken config worth blowing up over.
      def validate_display_mode!(mode)
        return if @display_mode_validated

        @display_mode_validated = true
        return if mode.nil?
        return unless @filter_form.respond_to?(:group_by_enabled?) && @filter_form.group_by_enabled?
        return unless @filter_form.respond_to?(:display_mode) && @filter_form.display_mode.nil?
        return if @filter_form.group_by_modes.include?(mode)

        raise ArgumentError,
              format(DISPLAY_MODE_MISMATCH_MESSAGE, mode, @filter_form.group_by_modes.join(", "), mode)
      end

      # Base for the page links, or `nil` to let the Pagy build its own.
      #
      # `nil` when the Pagy is linkable —the `pagy()` helper case, that is, every normal
      # host— and that is deliberate: handing a base to the `PaginationFooter` makes it WIN
      # (see PagyAdapter#page_url, #654), and this listing's `url:` is the filtering and
      # sorting base, which the host passes without a query string (`admin_movies_path`).
      # Forwarding it blindly turned `/movies?q[name_cont]=a&page=1` into `/movies?page=2`:
      # the applied filter was lost when paging. With the Pagy in place, Pagy composes the
      # URL from the real request and the narrowing survives, besides honouring its own
      # options (`root_key:`, `querify:`, `limit_key:`, `absolute:`) that this base cannot
      # reproduce.
      #
      # A Pagy WITHOUT a request —`Pagy::Offset.new` by hand, `render_inline`— cannot build
      # anything and fell back to a bare `?page=2` that wipes the browser's whole query
      # string. There a base is needed, and the listing already knows how to build it: the
      # SAME one the view switch and "Agrupar por" build (`url:` + the current query string,
      # minus the single-use params, `page` among them). That way the page links preserve
      # filters, sorting and saved view instead of only pointing at the right path. Until
      # now the DataTable forwarded NOTHING and that host had no parameter at all to fix it
      # with (#756).
      def pagination_url
        return if @pagy.nil? || pagy_adapter.linkable?

        build_toolbar_href(@url, request_query_params, :page, nil)
      end

      def pagy_adapter
        @pagy_adapter ||= Bali::Pagination::PagyAdapter.new(@pagy)
      end

      # N for the "select the N results" offer: the total of the FILTERED result, which is
      # exactly what the listing's pagy counts. Without a pagy, or with countless pagination
      # (where `count` is nil by design), there is no N to offer and the bar offers nothing.
      def bulk_actions_total_count
        return unless @pagy && pagy_adapter.summarizable?

        pagy_adapter.count
      end

      def summary_position?(position)
        @show_summary && @summary_position == position && !summary?
      end

      # Zero results have no range to describe: "Showing 0-0 of 0 movies" is what came out
      # of a search with no results.
      def summarizable?
        @pagy.present? && pagy_adapter.summarizable?
      end

      def validate_summary_position(position)
        SUMMARY_POSITIONS.include?(position) ? position : :bottom
      end
    end
  end
end
