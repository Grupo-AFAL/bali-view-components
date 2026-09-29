# frozen_string_literal: true

require_relative "date_range_presets"
require_relative "filter_form/search_configuration"
require_relative "filter_form/filter_group_parser"
require_relative "filter_form/simple_filters_configuration"
require_relative "filter_form/group_by_configuration"
require_relative "filter_form/saved_views_configuration"
require_relative "filter_form/enum_casting"
require_relative "filter_form/default_filters"

module Bali
  # FilterForm provides a unified interface for Ransack-based filtering with support
  # for both simple filters and complex AND/OR grouped conditions.
  #
  # @example Basic usage with attribute DSL
  #   class UsersFilterForm < Bali::FilterForm
  #     # Declare quick search fields (searches across multiple columns)
  #     search_fields :name, :email
  #
  #     # Declare filterable attributes for Filters UI
  #     filter_attribute :name, type: :text
  #     filter_attribute :email, type: :text
  #     filter_attribute :status, type: :select,
  #                      options: [['Active', 'active'], ['Inactive', 'inactive']]
  #     filter_attribute :created_at, type: :date
  #
  #     # Standard Ransack attributes for simple filtering
  #     attribute :name_cont
  #     attribute :status_eq
  #   end
  #
  #   # In controller
  #   @filter_form = UsersFilterForm.new(User.all, params, storage_id: 'users')
  #   @users = @filter_form.result
  #
  #   # In view - everything auto-configured from FilterForm
  #   data_table.with_filters_panel
  #
  # @example Using search_fields without subclassing
  #   @filter_form = Bali::FilterForm.new(
  #     Movie.all,
  #     params,
  #     search_fields: [:name, :genre, :tenant_name]
  #   )
  #
  class FilterForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include SearchConfiguration
    include FilterGroupParser
    include SimpleFiltersConfiguration
    include GroupByConfiguration
    include SavedViewsConfiguration
    include EnumCasting
    include DefaultFilters

    attr_reader :scope, :storage_id, :context, :clear_filters, :groupings, :view_param, :display_mode

    # Param carrying the display mode. It is THE SAME one as DataTable's `view_param:`: ONE
    # single literal so the two cannot drift apart (DataTable raises early if they differ,
    # see Bali::DataTable::Component#initialize).
    DEFAULT_VIEW_PARAM = :view

    # Ransack attribute for receiving the sort parameters
    attribute :s

    class << self
      # Widgets available in the SimpleFilters UI (valid `input:` values)
      SIMPLE_INPUTS = %i[select slim_select toggle_group radio_group boolean date
                         date_range number_range].freeze

      # Widgets that may carry `auto_submit: true`: the ones where a change event is
      # a completed choice. A pill click is the whole interaction, and a native
      # select only fires `change` when the menu closes on a selection (#996) — so
      # neither can cut the user off mid-value the way a date or a number range
      # would. `slim_select` stays out until its change semantics are verified
      # against the SlimSelect controller.
      AUTO_SUBMIT_INPUTS = %i[toggle_group radio_group select].freeze

      # Default SimpleFilters widget derived from the declared data type.
      # :text has no entry on purpose — quick text search belongs to search_fields.
      DEFAULT_SIMPLE_INPUT_FOR_TYPE = {
        select: :select, boolean: :boolean, date: :date, datetime: :date, number: :number_range
      }.freeze

      # Storage for filter attribute definitions used by Filters UI
      def filter_attributes
        @filter_attributes ||= []
      end

      # Define a filterable attribute. One declaration can feed BOTH filter UIs:
      # the advanced Filters popover (via #available_attributes) and, when
      # `simple: true`, the inline SimpleFilters row (via #simple_filters_config).
      #
      # @param key [Symbol] Attribute key (column name or Ransack association path)
      # @param type [Symbol] Data type: :text, :number, :date, :datetime,
      #   :select, :boolean. Drives the advanced UI operators and the default
      #   simple widget.
      # @param label [String, Proc, false] Human-readable label (defaults to humanized key).
      #   Zero-arity procs are resolved per-instance with instance_exec (useful
      #   for I18n lookups that must not be frozen at class-load time).
      #   `false` means "no caption" in the SimpleFilters row, for a row that reads
      #   fine without one. It is not the same as omitting it: omitted derives one
      #   from the Ransack attribute name, which for a path through an association
      #   is the predicate humanized in English. The advanced popover keeps a label
      #   either way — a row there needs a name.
      #
      #   `false` never means "no accessible name": the control still gets one, from
      #   `aria_label:` or, failing that, from the `blank:` text. Naming it through
      #   the blank option is what this keyword promised since #882 and did not do
      #   until #1155 — the blank option is the select's selected VALUE, not its name,
      #   so that last step is a safety net and not the thing to aim for: it names the
      #   control with the very text it reads out as its value ("All years, All years").
      #   Where the name matters, write `aria_label:`.
      # @param aria_label [String, Proc] Accessible name for the SimpleFilters control
      #   where no caption names it, and the only name available to the widgets that
      #   have no `blank:` to fall back on (boolean, toggle_group, radio_group,
      #   number_range, date, date_range). Same spelling as `search_fields aria_label:`
      #   (#1026). Zero-arity procs are resolved per-instance, like `label:`. It is not
      #   rendered as a caption, and it never competes with one: where there is a
      #   caption, the caption keeps naming the control — in every branch, the "Custom…"
      #   picker of a preset range included (#1155) — and this is ignored. A visible
      #   label has to be part of the accessible name (WCAG 2.5.3), so a second and
      #   different name would not be an improvement on the caption.
      # @param options [Array, Proc] For select types, array of [label, value]
      #   pairs or a zero-arity proc resolved per-instance with instance_exec —
      #   inside it you can use `scope` (the relation the controller passed in,
      #   typically already narrowed to the policy scope).
      # @param collection [Array, Proc] Alias of options, matching the key name
      #   the instance-level `simple_filters:` hashes use
      # @param simple [Boolean] Also render this attribute in the SimpleFilters UI
      # @param advanced [Boolean] Offer this attribute in the Filters popover
      #   (default true; pass false for an attribute that only belongs in the
      #   inline SimpleFilters row)
      # @param input [Symbol] SimpleFilters widget when it differs from the one
      #   derived from type (e.g. type: :select, input: :slim_select)
      # @param predicate [Symbol] Fixed Ransack predicate for the simple UI
      #   (default :eq; the advanced UI lets the user pick the operator)
      # @param blank [String, Proc] Blank option text for the simple UI
      # @param default [String, Boolean, Hash, Proc] The value this listing opens on.
      #   It preselects the simple control, and it is what
      #   {Bali::FilterForm::DefaultFilters.default_filter_params} emits so that
      #   `Bali::Filterable#redirect_to_default_filters` can put it in the URL — which
      #   is what makes it actually filter, survive sorting and paging, and stay
      #   removable. Needs a UI to live in: raises when the attribute is offered in
      #   neither (`simple: false, advanced: false`).
      # @param icon [String] Icon name for the simple UI
      # @param step [Numeric] Step for the :number_range simple widget
      # @param placeholder_min [String] Min placeholder for :number_range
      # @param placeholder_max [String] Max placeholder for :number_range
      # @param auto_submit [Boolean] Filter as soon as this control changes, instead
      #   of waiting for the Filter button. Opt-in per filter and off by default, so
      #   no existing row changes behaviour. Only for widgets whose change is a
      #   completed choice — `:toggle_group`, `:radio_group` and `:select`, see
      #   AUTO_SUBMIT_INPUTS above; a range would submit between the two halves of
      #   its value.
      # @param presets [Boolean, Array<Symbol>] Named periods offered by an
      #   `input: :date_range` widget, which then renders a period select whose
      #   "Custom…" option reveals the date picker. `true` offers all of
      #   {Bali::DateRangePresets::TOKENS}; an array picks and orders them. The
      #   chosen token travels in the same param the explicit range does and is
      #   resolved against `Time.zone` on every query, so a saved view that says
      #   "this month" still means this month next month.
      #
      # @example Advanced popover only (same as always)
      #   filter_attribute :name, type: :text
      #
      # @example Both UIs, collection narrowed to the policy scope
      #   filter_attribute :pm_id, type: :select, simple: true,
      #     options: -> { User.where(id: scope.select(:pm_id)).pluck(:name, :id) }
      #
      # @example Simple UI only, custom widget
      #   filter_attribute :priority, type: :select, simple: true, advanced: false,
      #     options: [['High', 'high'], ['Low', 'low']], input: :toggle_group
      #
      # @example Pills that filter on click
      #   filter_attribute :status, type: :select, simple: true, advanced: false,
      #     options: [['Draft', 'draft'], ['Published', 'published']],
      #     input: :radio_group, auto_submit: true
      #
      # @example Date range with named periods
      #   filter_attribute :created_at, type: :date, input: :date_range, simple: true,
      #     presets: %i[today this_week this_month], blank: 'Any date'
      # rubocop:disable Metrics/ParameterLists
      def filter_attribute(key, type: :text, label: nil, aria_label: nil, options: [],
                           collection: nil, simple: false, advanced: true, input: nil,
                           predicate: :eq, blank: nil, default: nil, icon: nil, step: nil,
                           placeholder_min: nil, placeholder_max: nil, auto_submit: false,
                           presets: nil)
        # rubocop:enable Metrics/ParameterLists
        type = type.to_sym
        resolved_input = simple ? resolve_simple_input(key, type, input) : input&.to_sym
        validate_auto_submit(key, resolved_input, auto_submit)
        validate_default(key, default, simple, advanced)

        filter_attributes << {
          key: key.to_sym,
          type: type,
          label: label || key.to_s.humanize,
          explicit_label: label,
          aria_label: aria_label,
          options: options.presence || collection || [],
          simple: simple,
          advanced: advanced,
          input: resolved_input,
          predicate: predicate&.to_sym,
          blank: blank,
          default: default,
          icon: icon,
          step: step,
          placeholder_min: placeholder_min,
          placeholder_max: placeholder_max,
          auto_submit: auto_submit,
          presets: Bali::DateRangePresets.normalize(presets, key: key, input: resolved_input)
        }
      end

      # Inherit filter_attributes from parent class
      # Note: search_fields inheritance is handled by SearchConfiguration concern
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@filter_attributes, filter_attributes.dup)
      end

      private

      # Validate an explicit simple `input:` or derive it from the data type.
      # Fails fast at class-definition time so a typo'd widget never renders
      # silently as a plain select.
      def resolve_simple_input(key, type, input)
        if input
          input = input.to_sym
          return input if SIMPLE_INPUTS.include?(input)

          raise ArgumentError, "filter_attribute #{key}: unknown input: :#{input} " \
                               "(valid: #{SIMPLE_INPUTS.join(', ')})"
        end

        DEFAULT_SIMPLE_INPUT_FOR_TYPE.fetch(type) do
          raise ArgumentError, "filter_attribute #{key}: type :#{type} has no simple filter " \
                               "widget; pass input: (one of #{SIMPLE_INPUTS.join(', ')}) or " \
                               "declare quick text search with search_fields"
        end
      end

      # A `default:` is the question the listing opens with, so it has to be visible and
      # removable somewhere — the simple control or the advanced panel. On an attribute
      # offered in NEITHER it would apply and there would be no way to see or drop it,
      # which is precisely the silent mismatch `default_filter_params` exists to end.
      # Fails at class-definition time, like the two guards around it (#1096).
      def validate_default(key, default, simple, advanced)
        return if default.nil? || default == ""
        return if simple || advanced

        raise ArgumentError, "filter_attribute #{key}: default: needs a UI to live in — " \
                             "declare `simple: true`, or leave `advanced:` on. A default " \
                             "on an attribute offered nowhere filters invisibly."
      end

      # Fails at class-definition time rather than rendering a row whose `auto_submit:`
      # nothing reads — the same contract as an unknown `input:`.
      def validate_auto_submit(key, widget, auto_submit)
        return unless auto_submit
        return if AUTO_SUBMIT_INPUTS.include?(widget)

        raise ArgumentError,
              "filter_attribute #{key}: auto_submit: true only applies to single-choice " \
              "widgets (#{AUTO_SUBMIT_INPUTS.join(', ')}) declared with simple: true; " \
              "this one is #{widget ? ":#{widget}" : 'not a simple filter'}"
      end
    end

    # @param scope [ActiveRecord::Relation] The base scope to filter
    # @param params [Hash, ActionController::Parameters] Request params containing q[...].
    #   A `q` that is not a hash (`?q=x`, `?q[]=x`) is ignored and the listing comes out
    #   unfiltered.
    # @param storage_id [String] Optional cache key for persisting filters
    # @param context [String] Optional context for cache key namespacing
    # @param search_fields [Array<Symbol>] Fields for quick text search (alternative to DSL)
    # @param search_placeholder [String] Placeholder text for search input
    # @param persist_enabled [Boolean] Whether user has opted into filter persistence
    #   (default: false). When false, filters are saved but not restored.
    # @param simple_filters [Array<Hash>] Simple inline filters (alternative to DSL)
    # @param saved_views_store [Object, Symbol] Store for named saved views — an
    #   app-provided object with the list/find/save/delete contract, or `:default` for the
    #   engine's own storage (Bali::SavedView) scoped to `saved_views_owner:` and
    #   `storage_id:` (see SavedViewsConfiguration)
    # @param saved_views_owner [Object] Owner of the `:default` store (e.g. current_user);
    #   ignored when an explicit store object is given
    # @param group_by_modes [Array<Symbol>] Display modes that APPLY the grouping
    #   (default `[:table]`). Outside them the grouping is suspended: the control hides and
    #   the ordering does not run, but the param survives (see GroupByConfiguration)
    # @param view_param [Symbol] URL param carrying the display mode
    #   (default `:view`). It has to be THE SAME one as DataTable's
    # @param display_mode [Symbol, String] The mode the listing is going to RENDER, for when
    #   the URL param is not enough to know it: a listing whose default view is not the table
    #   (the view switch declares the cards first) lands without `?view=` and the form,
    #   looking only at the URL, would believe it is on the table and would apply the grouping
    #   over the cards. Pass THE SAME thing you pass to DataTable (e.g. `params[:view] || :grid`)
    # rubocop:disable Metrics/ParameterLists
    def initialize(scope, params = {}, storage_id: nil, context: nil, search_fields: nil,
                   search_placeholder: nil, search_icon: nil, search_aria_label: nil,
                   search_width: nil, search_label: nil,
                   persist_enabled: nil, simple_filters: nil,
                   group_by_attributes: nil, group_by_modes: nil, view_param: nil, display_mode: nil,
                   saved_views_store: nil, saved_views_owner: nil)
      # rubocop:enable Metrics/ParameterLists
      # `search_label:` mirrors the DSL's old `label:` and was renamed with it
      # (#1026): the value is the box's aria-label, and the accessible-name
      # spelling across the library is `aria_label`.
      if search_label
        raise ArgumentError,
              "#{self.class.name}: `search_label:` was renamed to `search_aria_label:` in v3.1."
      end

      @scope = scope
      @storage_id = storage_id
      @context = context
      @instance_search_fields = search_fields&.map(&:to_sym)
      @instance_search_icon = search_icon
      @instance_search_label = search_aria_label
      @instance_search_width = search_width
      @instance_simple_filters = simple_filters
      @instance_group_by_attributes = group_by_attributes
      @instance_group_by_modes = group_by_modes
      @view_param = (view_param || DEFAULT_VIEW_PARAM).to_sym
      @search_placeholder = search_placeholder
      # nil vs false matters (#999): an explicit `persist_enabled: false` is a
      # read opt-in ("this browser said no"); nil means NOBODY read the cookie,
      # which with a storage_id present is the silent failure mode — the toggle
      # renders, the state saves, and it never restores. DataTable warns on it
      # in development; `Bali::Filterable#filter_form` is the wiring that cannot
      # forget.
      @persist_enabled_read = !persist_enabled.nil?
      @persist_enabled = persist_enabled.nil? ? false : persist_enabled
      @clear_filters = params.fetch(:clear_filters, false)
      @clear_search = params.fetch(:clear_search, false)
      @saved_views_store = resolve_saved_views_store(saved_views_store, saved_views_owner)
      @saved_view_param = params[:saved_view].presence
      # ORIGIN vs APPLICATION, the same separation group_by makes. `saved_view` APPLIES (it
      # overwrites the state with the payload) and that is why #669 took it out of the filter
      # forms: preserving it re-applied the view on top of what the user had just typed. But
      # losing it also loses KNOWING which view the state came from, and without that there is
      # no way to offer "Update 'X'". `view_origin` is that datum and is NEVER applied: it
      # only remembers.
      @saved_view_origin_param = params[:view_origin].presence || @saved_view_param
      @group_by = resolve_group_by(params[:group_by])
      # The param ARRIVING is different from it carrying a valid value: "no grouping" arrives
      # as `?group_by=` and has to beat the grouping stored in the filter cache (see
      # #fetch_stored_filter_state). Without this distinction, turning the grouping off with
      # persistence on resurrected it on the next render.
      @group_by_requested = params.key?(:group_by)
      # Has ANYONE said anything about grouping? A saved view payload and the filter cache
      # turn it on too. It gates the declared `default:` (#1156).
      @group_by_chosen = @group_by_requested
      # The grouping is SUSPENDED outside the modes that apply it (default: table), but the
      # param stays alive: coming back to the table finds it as it was left. The mode the host
      # passes wins over the URL: it is the only one that knows which view a listing that does
      # not have `?view=` yet renders (see the @param display_mode). `.to_s` first because this
      # arrives raw from the URL and a nested param (`?view[]=x`) does not respond to `to_sym`;
      # an unknown value simply is not in group_by_modes and suspends, which is the safe side
      # (grouping more than asked for is what you do not see coming).
      @display_mode = (display_mode || params[@view_param]).to_s.presence&.to_sym

      q_params = normalized_q_params(params)
      @q_params = q_params # Store for simple_filters value extraction
      perm_attrs = permitted_attributes
      permitted = q_params.permit(perm_attrs)
      permitted_h = permitted.to_h
      attributes = permitted_h.select { |k, _| self.class.attribute_names.include?(k.to_s) }

      # Extract Ransack groupings (g) and combinator (m) for complex filters
      # These are used by Filters for AND/OR condition groups
      @groupings = extract_groupings(q_params)
      @combinator = sanitized_combinator(q_params[:m])

      # Capture quick search value from params
      @search_value = extract_search_value(q_params)

      # Permit simple filter keys on @q_params so values can be read via
      # current_simple_filter_value. These are NOT added to `attributes` —
      # simple filter values bypass ActiveModel and go straight to Ransack.
      @q_params = q_params.permit(perm_attrs) if self.simple_filters_enabled?

      # ORIGIN vs VALUE, the same distinction `@group_by_requested` makes for the grouping,
      # and for the same reason: the SimpleFilters form sends ALL of its controls, so emptying
      # a select arrives as `q[genre_eq]=` — an explicit choice whose value is empty. Looking
      # only at the values it cannot be told apart from "nothing arrived", and with
      # persistence on that falls into the restore branch, which handed the user back the
      # filter they had just cleared. It is captured BEFORE applying a saved view, which
      # replaces `@q_params` with the view's state.
      @simple_filters_requested = simple_filter_params?(@q_params)

      # Saved view applied by URL (?saved_view=<id>): its payload REPLACES whatever state had
      # come in q — a view is a complete state, not a merge. It goes BEFORE persistence so the
      # view's state is written as the listing's "last state" (fetch_stored_filter_state sees
      # it as freshly submitted filters).
      saved_view_applied = current_saved_view.present?
      attributes = apply_saved_view_state if saved_view_applied

      # Persist/restore all filter state (attributes, groupings, combinator, search)
      if storage_id.present?
        attributes, @groupings, @combinator, @search_value = fetch_stored_filter_state(
          attributes, @groupings, @combinator, @search_value, force_write: saved_view_applied
        )
      end

      # Last, after persistence — see {GroupByConfiguration#apply_default_group_by} (#1156).
      apply_default_group_by

      super(attributes)
    end

    # Check if user has opted into filter persistence
    def persist_enabled?
      @persist_enabled
    end

    # Whether the persistence opt-in was actually read when this form was built
    # (an explicit true OR false — as opposed to nobody having looked). See the
    # initializer note; DataTable's dev/test warning keys off this.
    def persistence_opt_in_read?
      @persist_enabled_read
    end

    def permitted_attributes
      (scalar_attributes + date_range_attributes + array_attributes.map { |a| { a => [] } } +
       simple_filters_permitted_keys).uniq
    end

    # To define array attributes the user needs to specify an array as
    # it's default value.
    #
    # e.g.
    # attribute :vendors_id_in, default: []
    #
    def array_attributes
      @array_attributes ||= self.class.attribute_names.select do |attribute_name|
        array_predicates.any? { |predicate| attribute_name.to_s.ends_with?(predicate) }
      end
    end

    def scalar_attributes
      @scalar_attributes ||= self.class._default_attributes.keys - non_scalar_attributes
    end

    def non_scalar_attributes
      @non_scalar_attributes ||= array_attributes + date_range_attributes
    end

    def date_range_attributes
      @date_range_attributes ||= begin
        class_date_range_attrs = self.class.attribute_names.filter do |key|
          self.class.attribute_types[key].instance_of?(Bali::Types::DateRangeValue)
        end
        (class_date_range_attrs + simple_date_range_attributes.map(&:to_s)).uniq
      end
    end

    silence_warnings do
      def model_name
        @model_name ||= ActiveModel::Name.new(self, nil, "q")
      end
    end

    def inspect
      "<#{self.class.name} attributes=[#{attribute_names.join(',')}]>"
    end

    def id
      @id ||= scope.cache_key
    end

    def cache_key
      @cache_key ||= "#{self.class.name.tableize};#{context};#{storage_id}"
    end

    # How many values are narrowing this listing right now. The quick search counts
    # as one: it cuts the result exactly like any other filter, and a toolbar that
    # reads "0 filters" over 3 of 200 rows is telling the user something false.
    # How many, and whether there are any, over the TWO halves a listing can be narrowed by:
    # the flat one (`active_filters`) and the nested one from the advanced panel
    # (`applied_filter_conditions`). They are not derived from the hash only because the hash
    # cannot carry the nested half — see the comment on `active_filters` and the one on
    # `FilterGroupParser#applied_filter_conditions`.
    #
    # #1085: `Table` picks its empty state with `active_filters?`, so a listing narrowed to
    # zero FROM THE ADVANCED PANEL painted "No entities yet" over a catalog of 1,563 — the
    # listing blamed the data for what the filters had done. It is the same defect the
    # `active_filters` comment documents having fixed for the search and the simple filters;
    # the third source was left out because it is the only one that does not travel flat.
    def active_filters_count
      active_filters.size + applied_filter_conditions.size
    end

    def active_filters?
      active_filters.any? || applied_filter_conditions.any?
    end

    # Every value narrowing the listing right now, keyed the way the query carries
    # it. Three sources, because a listing can be narrowed from three places and
    # only the first used to be represented here:
    #
    #   - attributes declared with the `filter_attribute` DSL, via `query_params`;
    #   - the simple filters, which never become ActiveModel attributes — a plain
    #     `FilterForm.new(scope, params, simple_filters: [...])` declares none, so
    #     `attribute_names` is just `["s"]` and this answered `{}` no matter what
    #     the user had chosen;
    #   - the quick search box, whose value never lived in `query_params` either.
    #
    # That mattered beyond the count: `Table` picks its empty state from
    # `active_filters?`, so a search or a simple filter that cut the result to zero
    # got "No records yet" plus an invitation to create one, instead of "No results"
    # — the listing blamed the data for what the filters had done.
    #
    # The advanced panel is the one source that is NOT here, and on purpose: its conditions
    # travel nested (`q[g][0][name_cont]`) while this hash is re-emitted flat under `q`, so
    # a condition put in here would go out TWICE — once nested by
    # `ActiveFilterParams.group_pairs` and once flat by this hash. It is counted separately;
    # `active_filters?` above sums the two halves (#1085).
    #
    # `"s"` is Ransack's *sort* param, not a filter, and stays out.
    #
    # Date ranges declared as `attribute` (#966) need their own source too: `result`
    # applies them with a `where` on the relation, outside Ransack, so `query_params`
    # excludes them by construction — the filter narrowed the listing but did not
    # exist for anything consulting here. A simple date range wins on key collision:
    # it travels raw (a preset like `this_month` stays a token the server re-resolves),
    # while the attribute form travels frozen, already resolved.
    def active_filters
      @active_filters || begin
        filters = query_params.except("s").compact_blank
                              .merge(active_date_range_filters)
                              .merge(active_simple_filters)
        filters[search_field_name] = search_value if search_enabled? && search_value.present?
        filters
      end
    end

    # Get the available filter attributes defined via filter_attribute DSL.
    # Used by Filters component for rendering the filter UI.
    #
    # Entries declared with `advanced: false` are excluded. `label:`/`options:`
    # given as zero-arity procs are resolved here with instance_exec, so they
    # can use instance context — most importantly `scope`, the (typically
    # policy-scoped) relation the controller passed in.
    #
    # Override this method for full control; the Filters component consumes
    # whatever it returns.
    #
    # @return [Array<Hash>] Array of attribute definitions with :key, :type, :label, :options
    def available_attributes
      @available_attributes ||=
        self.class.filter_attributes.reject { |attr| attr[:advanced] == false }.map do |attr|
          {
            key: attr[:key],
            type: attr[:type],
            label: resolve_definition_value(attr[:label]) || attr[:key].to_s.humanize,
            options: resolve_definition_value(attr[:options]) || []
          }
        end
    end

    def query_params
      @query_params ||= non_date_range_attribute_names.index_with do |attr_name|
        (value = send(attr_name.to_sym)).is_a?(Array) ? value.compact_blank.presence : value
      end
    end

    def result(options = {})
      @result ||= begin
        relation = ransack_search.result(**options)

        date_range_attributes.each do |date_range_attr|
          value = if respond_to?(date_range_attr)
                    send(date_range_attr)
          else
                    current_simple_filter_value(date_range_attr, nil)
          end

          # Manually cast if it's a string from params
          if value.is_a?(String)
            value = Bali::Types::DateRangeValue.new.cast(value)
          end

          next if value.blank?

          relation = relation.where(date_range_attr => value)
        end

        # Last, over the already-built relation: the ORDER BY of a grouping with an explicit
        # `sql:` does not fit Ransack's `s` param, which only speaks names. The diagnostics
        # wrap goes OVER that reorder so it covers all four grouping shapes, not only `sql:`
        # (see #apply_group_by_diagnostics).
        apply_group_by_diagnostics(apply_group_by_sql_order(relation))
      end
    end

    def ransack_search
      @ransack_search ||= scope.ransack(ransack_params)
    end

    # Build params hash for Ransack including groupings and search
    def ransack_params
      params = query_params.dup

      # Add groupings for Filters complex conditions
      params[:g] = @groupings if @groupings.present?
      params[:m] = @combinator if @combinator.present?

      # Add quick search parameter
      params[search_field_name] = @search_value if search_enabled? && @search_value.present?

      # Add simple filter parameters
      add_simple_filter_params(params) if simple_filters_enabled?

      # Group-first ordering (sort-within-groups) when grouping is active
      apply_group_by_ordering(params)

      # Last step and over a copy: the state that is RENDERED (filter_groups, the pills, a
      # saved view's payload, the persistence cache) keeps speaking in labels, which is what
      # the `<option value>` carries. See EnumCasting.
      cast_enum_labels(params)
    end

    private

    # Resolve a DSL value that may be callable. Zero-arity procs run under
    # instance_exec so they can reference the form instance (e.g. `scope`);
    # other callables are invoked as-is.
    def resolve_definition_value(value)
      return value unless value.respond_to?(:call)

      value.is_a?(Proc) && value.arity.zero? ? instance_exec(&value) : value.call
    end

    def non_date_range_attribute_names
      attribute_names - date_range_attributes
    end

    # The date ranges declared as `attribute`, serialized the way a form can re-emit
    # them as hidden fields: `begin..end` — the exact shape `DateRangeValue` casts
    # back, with either end blank for an open range. `date_range_attributes` also
    # lists the simple-filter ones, which never become ActiveModel attributes (no
    # reader), so `respond_to?` filters them out — same guard `result` uses.
    def active_date_range_filters
      date_range_attributes.filter_map do |attr_name|
        next unless respond_to?(attr_name)

        value = public_send(attr_name)
        next if value.blank?

        value = "#{value.begin}..#{value.end}" if value.is_a?(Range)
        [ attr_name, value ]
      end.to_h
    end

    # Extract Ransack groupings from params.
    # Groupings format: q[g][0][field_operator]=value, q[g][0][m]=or/and
    #
    # Safety: to_unsafe_h is required because Ransack expects a plain nested hash
    # for its grouping structure. Ransack performs its own attribute authorization
    # via `ransackable_attributes` / `ransackable_associations` on the model,
    # so arbitrary keys are rejected at the Ransack layer, not here.
    #
    # Every group has to be a hash and `g` can arrive in any shape: `q[g][]` (the ARRAY shape,
    # which Ransack accepts and Bali does not emit) blew up with a NoMethodError on
    # `to_unsafe_h`, and a scalar group (`q[g][0]=x`) travelled whole down to Ransack to blow up
    # there — a 500 on any index from a hand-written URL. It is normalized to the indexed shape
    # the rest of Bali speaks (filter_groups, a saved view's payload, EnumCasting), so the array
    # shape also GOES THROUGH the enum translation instead of silently dodging it and returning
    # the opposite records.
    #
    # `?q=anything` and `?q[]=anything` arrive as a String and as an Array, and neither of them
    # responds to `permit`: they are typed into the address bar with no session and knowing
    # nothing about the app, so the bare `permit` that used to be here was a 500 any visitor
    # could fire on any listing. And `q` is not only the filters — the sort (`s`), the groupings
    # (`g`) and the combinator (`m`) come out of there too —, so every reader failed in its own
    # way further down. A `q` that is not a hash asked for nothing, and the listing comes out
    # unfiltered; rejecting the request would be inventing an intention for what is garbage.
    #
    # The bare Hash is wrapped because the signature accepts it and `Hash#permit` does not exist
    # either: the `params = {}` default itself died here, so `FilterForm.new(scope)` — and any
    # host building the form outside a request, a job or an export — never worked.
    def normalized_q_params(params)
      q = params.fetch(:q, {})
      return q if q.is_a?(ActionController::Parameters)

      ActionController::Parameters.new(q.is_a?(Hash) ? q.to_h : {})
    end

    def extract_groupings(q_params)
      groupings = q_params[:g]
      return nil if groupings.blank?

      groups = unwrap_params(groupings)
      groups = groups.each_with_index.to_h { |group, index| [ index.to_s, group ] } if groups.is_a?(Array)
      return nil unless groups.is_a?(Hash)

      groups.transform_values { |group| unwrap_params(group) }
            .select { |_index, group| group.is_a?(Hash) }.presence
    end

    def unwrap_params(value)
      value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
    end

    # Persist or restore complete filter state including groupings, combinator, and search.
    # Returns [attributes, groupings, combinator, search_value] tuple.
    #
    # Behavior depends on @persist_enabled:
    # - Always saves filters when user submits new ones (so they're available if user enables later)
    # - Only restores filters when @persist_enabled is true
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # `force_write:` — a saved view just applied ALWAYS counts as "freshly submitted filters",
    # even when its payload results in an empty state (a "see everything" view). Without this,
    # `has_filter_params` cannot tell "nothing arrived" from "an empty view arrived" and with
    # `persist_enabled` it falls into the restore branch — the old cache overwrites the applied
    # view.
    def fetch_stored_filter_state(attributes, groupings, combinator, search_value, force_write: false)
      return [ attributes, groupings, combinator, search_value ] unless Object.const_defined?("Rails")

      has_filter_params = force_write || attributes.present? || groupings.present? ||
                          search_value.present? || @simple_filters_requested

      if has_filter_params
        # User submitted new filters → always save complete state. `group_by` travels with the
        # rest: without it, coming back to the listing restored the filters but lost the
        # grouping (and a saved view that groups stopped being recognized as active).
        Rails.cache.write(cache_key, {
                            attributes: attributes.to_h,
                            groupings: groupings,
                            combinator: combinator,
                            search_value: search_value,
                            group_by: @group_by,
                            # `group_by: nil` alone cannot tell "I turned it off" from
                            # "nobody said anything" (#1156).
                            group_by_chosen: @group_by_chosen,
                            # Same key and same shape as the saved views' `PAYLOAD_KEYS`: the
                            # round-trip is the one that already exists
                            # (`active_simple_filters` writes, `apply_simple_filter_state`
                            # restores, `current_simple_filter_value` reads), not a second one.
                            simple_filters: active_simple_filters
                          })
        [ attributes, groupings, combinator, search_value ]
      elsif @clear_filters
        # User clicked "Clear all" → delete stored filters
        Rails.cache.delete(cache_key)
        [ {}, nil, nil, nil ]
      elsif @clear_search
        # User clicked search clear button → clear just the search from storage. With
        # persistence off NOTHING is restored: the user explicitly asked the server not to hand
        # them back state, and clearing the search cannot be the back door through which
        # filters the URL no longer describes reappear.
        stored = @persist_enabled ? Rails.cache.fetch(cache_key) : nil
        if stored.is_a?(Hash)
          # The simple filters survive the merge — only the search is nulled — and come out
          # through the side effect: clearing the search cannot take the selects with it.
          # `clearSearch` navigates discarding every `q[...]` (see preservedParamsUrl), so the
          # cache is the ONLY source of what the user had chosen.
          stored = stored.merge(
            search_value: nil,
            attributes: attributes_without_search_field(stored[:attributes])
          )
          Rails.cache.write(cache_key, stored)
          restore_simple_filter_state(stored)
          [ stored[:attributes] || {}, stored[:groupings], stored[:combinator], nil ]
        else
          [ {}, nil, nil, nil ]
        end
      elsif @persist_enabled
        # No filters in URL and persistence enabled → restore from cache
        stored = normalize_stored_state(Rails.cache.fetch(cache_key))
        if @group_by_requested
          # The URL wins, the same as with a saved view (see #apply_saved_view_state). Choosing
          # a grouping arrives ONLY as `?group_by=` — the filters live in the cache, so the URL
          # does not carry them and this is the branch that runs —, and restoring here
          # overwrote the click just made with the old grouping: the control did nothing, and
          # the cards↔table round trip lost the grouping on the way. It is SAVED as well as
          # rendered: without writing it, that same render came out right and the next request
          # without the param resurrected the old grouping — the same symptom, one request later.
          Rails.cache.write(cache_key, stored.merge(group_by: @group_by, group_by_chosen: true))
        elsif stored[:group_by_chosen] || stored[:group_by].present?
          # The stored CHOICE, not the mere presence of the key: an unmarked `group_by: nil`
          # is what any filter submit writes on a listing that does not group, so reading it
          # as a choice killed the declared `default:` on every listing ever used (#1156).
          @group_by = resolve_group_by(stored[:group_by])
          @group_by_chosen = true
        end
        restore_simple_filter_state(stored)
        [
          stored[:attributes] || {},
          stored[:groupings],
          stored[:combinator],
          stored[:search_value]
        ]
      else
        # Persistence not enabled → don't restore, return empty
        [ {}, nil, nil, nil ]
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    # The search term enters the cache through TWO doors when the host declares the Ransack
    # predicate as an attribute on top of `search_fields` — the natural shape when the quick
    # search box also takes part in the advanced filters:
    #
    #   search_fields :email, :first_name
    #   attribute :email_or_first_name_cont      # <- the second door
    #
    # `extract_search_value` picks it up into `search_value`, and since the key is ALSO in
    # `attribute_names` it lands in `attributes` all the same. Nulling only the first left the
    # predicate inside the restored attributes: the box was empty and the listing stayed
    # narrowed by a term no longer visible anywhere — and since the cache was rewritten with it
    # inside, on every later visit too (#1017).
    def attributes_without_search_field(attributes)
      return attributes unless search_enabled? && attributes.is_a?(Hash)

      attributes.except(search_field_name.to_s, search_field_name.to_sym)
    end

    # The simple filters are restored through a SIDE EFFECT and not through the tuple, because
    # their value is never an ActiveModel attribute: it lives in `@q_params` and goes straight
    # to Ransack. It is exactly what a saved view already does, so its path is reused instead of
    # opening a second one.
    #
    # `apply_simple_filter_state` REPLACES `@q_params`, it does not merge — a restored state is
    # complete, just like a view. That is why this is only reached from the branches where the
    # URL asked for no simple filter (`@simple_filters_requested` sends those to the write
    # branch): otherwise this would overwrite the filter just chosen with the old one.
    def restore_simple_filter_state(stored)
      return unless simple_filters_enabled?

      apply_simple_filter_state(stored[:simple_filters])
    end

    # Old cache format: only the attributes, without the complete state's keys. It is
    # normalized on the way in so the rest of the branch speaks a single shape — restoring and
    # writing back have to see the SAME hash or the cache ends up telling a different story.
    def normalize_stored_state(stored)
      return stored if stored.is_a?(Hash) && stored[:attributes]

      { attributes: stored || {} }
    end

    def array_predicates
      %w[_any _all _not_in _in]
    end
  end
end
