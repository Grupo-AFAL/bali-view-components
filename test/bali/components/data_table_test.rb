# frozen_string_literal: true

require "test_helper"

# Form with a declared grouping, for the preserved_params round trip.
class GroupableDataTableFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Género"

  attribute :genre_eq
end

class DefaultGroupingDataTableFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Genre"
  group_by_attribute :status, default: true

  attribute :genre_eq
end

class BaliDataTableComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  def component
    Bali::DataTable::Component.new(url: "/", **@options)
  end

  def filter_attributes
    [ { key: :name, type: :text, label: "Name" } ]
  end

  def test_renders_without_summary
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("div.filters")
    assert_selector("div.table-component")
  end

  def test_renders_with_summary
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_summary { "<p>Summary</p>".html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("div.filters")
    assert_selector("div.table-component")
    assert_selector("p", text: "Summary")
  end

  def test_renders_without_filters_panel
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_no_selector("div.filters")
    assert_selector("div.table-component")
  end

  def test_renders_toolbar_buttons
    render_inline(component) do |c|
      c.with_toolbar_button { '<button class="btn">Export</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component")
    assert_selector("button.btn", text: "Export")
  end

  # --- Grouping (group_by control + round-trip) ---

  def grouping_filter_form(group_by: "genre", view: nil, **options)
    Bali::FilterForm.new(
      Movie.all,
      ActionController::Parameters.new(
        q: ActionController::Parameters.new({}), group_by: group_by, view: view
      ),
      simple_filters: [ { attribute: :genre, collection: [ %w[Action Action] ], blank: "All" } ],
      group_by_attributes: %i[genre status],
      **options
    )
  end

  # `group_by: :unset` means the URL says nothing, which is when the default speaks.
  def default_grouping_filter_form(group_by: :unset)
    params = { q: ActionController::Parameters.new({}) }
    params[:group_by] = group_by unless group_by == :unset

    DefaultGroupingDataTableFilterForm.new(Movie.all, ActionController::Parameters.new(params))
  end

  def test_renders_group_by_control_when_filter_form_declares_group_by
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector(".dropdown a[href*='group_by=genre']")
    assert_selector(".dropdown a[href*='group_by=status']")
  end

  def test_does_not_render_group_by_control_without_declared_attributes
    filter_form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(q: {}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: filter_form)) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector("a[href*='group_by=']")
  end

  def test_simple_filters_preserve_active_group_by_as_hidden_field
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_filters_panel_preserves_active_group_by_as_hidden_field
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  # --- #677: both filter slots resolve `search:` the same way ---

  def searchable_filter_form
    Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new({}),
      search_fields: %i[name genre], search_placeholder: "Declared"
    )
  end

  def test_both_filter_slots_take_the_search_config_the_filter_form_declares
    %i[with_simple_filters with_filters_panel].each do |slot|
      render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: searchable_filter_form)) do |c|
        c.public_send(slot)
        c.with_table { '<div class="table-component"></div>'.html_safe }
      end

      assert_selector("input[name='q[name_or_genre_cont]'][placeholder='Declared']", visible: :all)
    end
  end

  def test_an_explicit_search_option_overrides_only_the_keys_it_names
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: searchable_filter_form)) do |c|
      c.with_simple_filters(search: { placeholder: "Overridden" })
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # The declared columns survive an override that only names the placeholder.
    assert_selector("input[name='q[name_or_genre_cont]'][placeholder='Overridden']", visible: :all)
  end

  def test_no_group_by_hidden_field_when_grouping_inactive
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(group_by: nil))) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector("input[type=hidden][name=group_by]", visible: :all)
  end

  # --- Suspension in cards: the control is hidden, NOT the param ---

  def test_grid_mode_keeps_the_group_by_hidden_field
    # ANTI-REGRESSION: the hidden field gates on STATE (`group_by_active?`), not on
    # APPLICATION. "Fix" it to `group_by_applied?` and searching while in cards wipes the
    # grouping, so coming back to the table no longer finds it.
    form = grouping_filter_form(view: "grid")
    assert(form.group_by_suspended?, "el form tiene que estar suspendido para que el test valga")

    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: form, display_mode: :grid)
    ) do |c|
      c.with_simple_filters
      c.with_grid { '<div class="grid-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_the_suspended_control_offers_no_grouping_links
    render_inline(
      Bali::DataTable::Component.new(
        url: "/movies", filter_form: grouping_filter_form(view: "grid"), display_mode: :grid
      )
    ) do |c|
      c.with_grid { '<div class="grid-component"></div>'.html_safe }
    end

    assert_no_selector(".dropdown a[href*='group_by=']")
  end

  def test_group_by_control_renders_again_back_in_table_mode
    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(view: "table"))
    ) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector(".dropdown a[href*='group_by=status']")
  end

  def test_raises_when_the_view_param_disagrees_with_the_filter_form
    # Out of sync there is NOTHING visible to give it away: the table looks the same and
    # suspension decides the other way (looking at a param the view switch never writes).
    error = assert_raises(ArgumentError) do
      Bali::DataTable::Component.new(
        url: "/movies", filter_form: grouping_filter_form, view_param: :modo
      )
    end
    assert_match("view_param", error.message)
  end

  def test_does_not_raise_on_a_custom_view_param_shared_with_the_filter_form
    component = Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form(view_param: :modo), view_param: :modo
    )
    assert(component)
  end

  def test_does_not_raise_on_a_custom_view_param_when_the_listing_has_no_grouping
    # With no declared grouping the display mode changes no decision the form makes.
    form = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(q: {}))
    assert(Bali::DataTable::Component.new(url: "/movies", filter_form: form, view_param: :modo))
  end

  def test_raises_when_the_listing_renders_a_mode_the_form_never_heard_about
    # The mode is derived TWICE: the DataTable resolves it against the declared views and the
    # form reads it from the URL. With no `?view=`, a listing that declares the cards FIRST
    # paints cards while the form —seeing nil— applies the grouping anyway: the cards come back
    # reordered with no band to explain it.
    # Both classes: the host's block is evaluated inside the render, so depending on who is on
    # the stack ActionView may wrap the ArgumentError in a Template::Error.
    error = assert_raises(ArgumentError, ActionView::Template::Error) do
      render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form)) do |c|
        c.with_view_switch do |switch|
          switch.with_view(name: "Cards", icon: "grid-2x2", value: :grid)
          switch.with_view(name: "Table", icon: "list", value: :table)
        end
        c.with_grid { c.display_mode.to_s.html_safe }
      end
    end
    assert_match("display_mode", error.message)
  end

  def test_does_not_raise_when_the_host_hands_the_form_the_same_mode
    component = Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form(display_mode: :grid), display_mode: :grid
    )
    render_inline(component) do |c|
      c.with_view_switch do |switch|
        switch.with_view(name: "Cards", icon: "grid-2x2", value: :grid)
        switch.with_view(name: "Table", icon: "list", value: :table)
      end
      c.with_grid { c.display_mode.to_s.html_safe }
    end

    assert_text("grid")
  end

  def test_does_not_raise_on_an_unknown_view_param
    # An unknown `?view=` is something a user can type: the listing falls back to the first view
    # and the form suspends. A known and harmless limit — a 500 is not the answer to a typo.
    component = Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form(view: "bogus")
    )
    render_inline(component) do |c|
      c.with_view_switch do |switch|
        switch.with_view(name: "Table", icon: "list", value: :table)
      end
      c.with_table { c.display_mode.to_s.html_safe }
    end

    assert_text("table")
  end

  def test_a_suspended_grouping_leaves_the_control_in_place_but_inert
    # Hiding it moved the whole row on a mode change, and the notice that explained it took a
    # permanent strip to say what a disabled button already says.
    render_inline(
      Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(view: "grid"))
    ) do |c|
      c.with_grid { "".html_safe }
    end

    assert_selector("button.btn-disabled[title*='Table']", text: /Group by/)
    assert_no_selector("[data-dropdown-target='trigger']", text: /Group by/)
  end

  def test_explicit_preserved_params_do_not_drop_the_active_group_by
    # They used to be mutually exclusive: a host preserving its own params dropped the grouping
    # on every filter or search submit.
    form = GroupableDataTableFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "genre")
    )
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel(preserved_params: { view_mode: "cards" })
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='genre']", visible: :all)
    assert_selector("input[name='view_mode'][value='cards']", visible: :all)
  end

  # --- #1156: what travels when the listing declares `group_by_attribute default:` ---

  # A default is DERIVED and re-resolved every request: carried along, the next submit would
  # make it indistinguishable from a choice and write it to the cache.
  def test_a_default_only_grouping_does_not_travel_as_a_hidden_field
    render_inline(Bali::DataTable::Component.new(
      url: "/movies", filter_form: default_grouping_filter_form
    )) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { "".html_safe }
    end

    assert_no_selector("input[name='group_by']", visible: :all)
  end

  # Without this, filtering regrouped the listing the user had just ungrouped — and it has to
  # travel NAMED: an empty `group_by=` is dropped by the hidden fields and by `sort_link`.
  def test_an_explicit_no_grouping_travels_by_name_when_a_default_is_declared
    render_inline(Bali::DataTable::Component.new(
      url: "/movies", filter_form: default_grouping_filter_form(group_by: "none")
    )) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='none']", visible: :all)
  end

  # The control's "no grouping" item emits the same value as the hidden field, or the link and
  # the submit would say different things.
  def test_the_no_grouping_item_links_to_the_named_value_when_a_default_is_declared
    render_inline(Bali::DataTable::Component.new(
      url: "/movies", filter_form: default_grouping_filter_form
    )) do |c|
      c.with_table { "".html_safe }
    end

    assert_selector("a[href='/movies?group_by=none']")
  end

  # With no default it stays the empty `?group_by=`: changing it would move the URL of every
  # listing that already groups.
  def test_the_no_grouping_item_stays_empty_without_a_default
    render_inline(Bali::DataTable::Component.new(
      url: "/movies", filter_form: grouping_filter_form
    )) do |c|
      c.with_table { "".html_safe }
    end

    assert_selector("a[href='/movies?group_by=']")
  end

  def test_a_chosen_grouping_still_travels_with_its_name_over_a_default
    render_inline(Bali::DataTable::Component.new(
      url: "/movies", filter_form: default_grouping_filter_form(group_by: "genre")
    )) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='genre']", visible: :all)
  end

  # #1056: both filter slots treat `preserved_params` the same. The inline slot passed a fixed
  # `preserved_state_params`, so a param of the host's own (a tree's depth, say) was lost
  # SILENTLY on every submit of the row.
  def test_simple_filters_explicit_preserved_params_do_not_drop_the_active_group_by
    render_inline(Bali::DataTable::Component.new(url: "/movies",
                                                 filter_form: grouping_filter_form)) do |c|
      c.with_simple_filters(preserved_params: { profundidad: "todo" })
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='genre']", visible: :all)
    assert_selector("input[name='profundidad'][value='todo']", visible: :all)
  end

  # The direction of precedence is part of the contract: on a key collision the host's explicit
  # hash wins over the listing's state — in BOTH slots. Without these tests, flipping the
  # receiver of the merge would pass the whole suite.
  def test_filters_panel_explicit_preserved_param_beats_the_same_key_from_the_listing_state
    form = GroupableDataTableFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "genre")
    )
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel(preserved_params: { group_by: "status" })
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='status']", visible: :all)
    assert_no_selector("input[name='group_by'][value='genre']", visible: :all)
  end

  def test_simple_filters_explicit_preserved_param_beats_the_same_key_from_the_listing_state
    render_inline(Bali::DataTable::Component.new(url: "/movies",
                                                 filter_form: grouping_filter_form)) do |c|
      c.with_simple_filters(preserved_params: { group_by: "status" })
      c.with_table { "".html_safe }
    end

    assert_selector("input[name='group_by'][value='status']", visible: :all)
    assert_no_selector("input[name='group_by'][value='genre']", visible: :all)
  end

  # The Clear link is the row's other exit, and it carries the same thing the submit does:
  # without this, clearing the filters dropped the grouping and the host params the submit had
  # just preserved (parity with the panel's clearFiltersAndClose).
  def test_simple_filters_clear_link_keeps_the_listing_state_and_the_hosts_params
    form = Bali::FilterForm.new(
      Movie.all,
      ActionController::Parameters.new(
        q: ActionController::Parameters.new(genre_eq: "Action"), group_by: "genre"
      ),
      simple_filters: [ { attribute: :genre, collection: [ %w[Action Action] ], blank: "All" } ],
      group_by_attributes: %i[genre status]
    )
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_simple_filters(preserved_params: { profundidad: "todo" })
      c.with_table { "".html_safe }
    end

    assert_selector("a[href='/movies?clear_filters=true&group_by=genre&profundidad=todo']")
  end

  # --- Surface: the content slot brings it, not the host and not the toolbar ---

  def test_with_table_brings_its_own_surface_and_scroll_wrapper
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector(
      "div.data-table-component div.card > div.card-body > div.overflow-x-auto > div.table-component"
    )
  end

  def test_with_grid_renders_without_surface
    render_inline(component) do |c|
      c.with_grid { '<div class="cards"></div>'.html_safe }
    end

    # The cards ALREADY are the surface: a card around them would nest one inside another.
    assert_selector("div.cards")
    assert_no_selector("div.card")
    assert_no_selector("div.overflow-x-auto")
  end

  def test_with_content_defaults_to_surface_and_accepts_surface_false
    render_inline(component) do |c|
      c.with_content { '<div class="custom-view"></div>'.html_safe }
    end
    assert_selector("div.card > div.card-body > div.custom-view")

    # Content that brings its own chrome (a calendar) switches the surface off and does NOT lose the
    # block along the way.
    render_inline(component) do |c|
      c.with_content(surface: false) { '<div class="custom-view"></div>'.html_safe }
    end
    assert_selector("div.custom-view")
    assert_no_selector("div.card")
  end

  def test_the_toolbar_row_has_no_surface
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # The toolbar is the SAME row in every mode: bare, a direct child of the component. The only
    # card on the page is the content's, and the filters stay OUTSIDE.
    #
    # The row is named by its controller and not by its layout classes: written as
    # `div.flex.items-center`, this test —which is about the SURFACE— failed whenever the row's
    # alignment changed, which is not what it looks at.
    toolbar = "div.data-table-component > div[data-controller~='toolbar-overflow']"
    assert_selector("#{toolbar} div.filters")
    assert_no_selector("div.card div.filters")
    assert_no_selector("#{toolbar}.bg-base-100")
  end

  def test_declaring_two_content_slots_raises
    # Two declarations overwrote each other silently and the host always saw the last one: a mode
    # it did not pick. Now it fails loudly and teaches the if over display_mode.
    error = assert_raises(Bali::DataTable::Component::DuplicateContent) do
      render_inline(component) do |c|
        c.with_table { '<div class="table-component"></div>'.html_safe }
        c.with_grid { '<div class="cards"></div>'.html_safe }
      end
    end
    assert_match(/with_table/, error.message)
  end

  def test_table_class_option_overrides_the_scroll_wrapper_classes
    @options = { table_class: "overflow-x-auto max-h-96" }
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("div.card-body > div.overflow-x-auto.max-h-96 > div.table-component")
  end

  def test_content_slot_forwards_card_options_to_the_surface
    render_inline(component) do |c|
      c.with_table(style: :bordered, class: "mt-2") { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("div.card.card-border.mt-2 div.table-component")
  end

  # --- View switch ---

  def declare_views(component_instance)
    component_instance.with_view_switch do |switch|
      switch.with_view(name: "Tabla", icon: "list", value: :table)
      switch.with_view(name: "Tarjetas", icon: "grid-2x2", value: :grid)
    end
  end

  def test_view_switch_renders_in_the_toolbar
    render_inline(component) do |c|
      declare_views(c)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # With nothing else declared the toolbar still appears: the switch counts towards it.
    assert_selector("div.data-table-component .view-switch-component a", count: 2)
    assert_selector("a[href*='view=table']")
    assert_selector("a[href*='view=grid']")
  end

  def test_unknown_view_param_falls_back_to_the_first_declared_view
    # A `?view=` nobody declared cannot leave the listing empty: it falls back to the first view,
    # and the host reads that already-validated value to pick its content.
    @options = { display_mode: :bogus }

    render_inline(component) do |c|
      declare_views(c)
      if c.display_mode == :grid
        c.with_grid { '<div class="cards"></div>'.html_safe }
      else
        c.with_table { '<div class="table-component"></div>'.html_safe }
      end
    end

    assert_selector("div.table-component")
    assert_no_selector("div.cards")
    assert_selector("a.btn-active[href*='view=table']")
  end

  def test_declared_view_drives_the_content_and_the_active_link
    @options = { display_mode: :grid }

    render_inline(component) do |c|
      declare_views(c)
      if c.display_mode == :grid
        c.with_grid { '<div class="cards"></div>'.html_safe }
      else
        c.with_table { '<div class="table-component"></div>'.html_safe }
      end
    end

    assert_selector("div.cards")
    assert_selector("a.btn-active[href*='view=grid']")
  end

  def test_view_param_option_renames_the_url_param
    @options = { view_param: :mode, display_mode: :grid }

    render_inline(component) do |c|
      declare_views(c)
      c.with_grid { '<div class="cards"></div>'.html_safe }
    end

    assert_selector("a[href*='mode=grid']")
    assert_no_selector("a[href*='view=']")
  end

  def test_display_mode_is_untouched_without_a_view_switch
    @options = { display_mode: :roadmap }
    assert_equal(:roadmap, component.display_mode)
  end

  def test_the_display_mode_falls_back_to_the_url_when_the_host_forgets_it
    # A host that declares the switch and forgets `display_mode:` used to get links that changed
    # the URL and never the view, silently: the component already has the query string in hand
    # (it builds those very hrefs with it).
    with_request_url "/admin/movies?view=grid" do
      render_inline(Bali::DataTable::Component.new(url: "/movies")) do |c|
        declare_views(c)
        assert_equal(:grid, c.display_mode)
        c.with_grid { '<div class="cards"></div>'.html_safe }
      end
    end

    assert_selector("a.btn-active[href*='view=grid']")
  end

  def test_the_view_taken_from_the_url_also_travels_as_a_hidden_field
    with_request_url "/admin/movies?view=grid" do
      render_inline(Bali::DataTable::Component.new(url: "/movies")) do |c|
        c.with_filters_panel(available_attributes: filter_attributes)
        declare_views(c)
        c.with_grid { '<div class="cards"></div>'.html_safe }
      end
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
  end

  SavedViewsStore = Struct.new(:views) do
    def list = views
    def find(id) = views.find { |view| view.id.to_s == id.to_s }
  end

  def saved_views_form
    Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new, storage_id: "movies_index",
      saved_views_store: SavedViewsStore.new([])
    )
  end

  def test_the_saved_views_control_declares_its_priority_and_keeps_its_label
    # Saved views is the control whose DUPLICATION caused #669, and the only one whose label is
    # dynamic (the active view's name): inside the ⋯ without a label it is an anonymous icon.
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: saved_views_form)) do |c|
      c.with_saved_views
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="memory"]' \
                    '[data-toolbar-overflow-priority="30"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-priority="30"] span.toolbar-control-label', visible: :all)
    assert_selector('[data-controller~="saved-views"]', count: 1, visible: :all)
  end

  def test_a_declared_control_that_renders_nothing_does_not_open_the_overflow_menu
    # `with_saved_views` over a form with no store leaves `render?` false. Looking at the slot's
    # predicate left an EMPTY wrapper that the JS moved into the ⋯, exposing a button that opens
    # a blank menu.
    formless = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new)
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: formless)) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_saved_views
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector('[data-toolbar-overflow-priority="30"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_the_toolbar_emits_the_overflow_threshold_it_gated_with
    render_collapsible_toolbar

    assert_selector('[data-controller~="toolbar-overflow"]' \
                    "[data-toolbar-overflow-threshold-value=\"#{Bali::DataTable::Component::OVERFLOW_THRESHOLD}\"]",
                    visible: :all)
  end

  def test_the_overflow_menu_is_a_container_not_a_menu_of_menuitems
    # Whole widgets land inside it (nested dropdowns, checkboxes, the rename form): `role="menu"`
    # exposes children that role does not allow.
    render_collapsible_toolbar

    assert_no_selector('[data-toolbar-overflow-target="overflow"] [role="menu"]', visible: :all)
    assert_selector('div[data-toolbar-overflow-target="menu"]', visible: :all)
  end

  def test_bulk_actions_puts_the_stimulus_controller_on_the_container
    render_inline(component) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector('div.data-table-component[data-controller~="bulk-actions"]')
  end

  def test_only_one_bulk_actions_controller_in_the_tree
    # Two nested controllers split the targets between them and the bar stops seeing the rows,
    # silently: that is why the slot asks for standalone: false.
    render_inline(component) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector('[data-controller~="bulk-actions"]', count: 1)
  end

  def test_bulk_actions_declares_each_action_exactly_once
    # ViewComponent evaluates the slot's block when it reads `actions`. Running it in the lambda
    # too duplicated every action without failing anywhere.
    render_inline(component) do |c|
      c.with_bulk_actions do |bulk|
        bulk.with_action(label: "Delete", href: "/delete")
        bulk.with_action(label: "Archive", href: "/archive")
      end
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector(".bulk-actions-component form", count: 2, visible: :all)
  end

  def test_container_has_no_bulk_actions_controller_without_the_slot
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector('[data-controller~="bulk-actions"]')
  end

  def test_bulk_actions_marks_the_toolbar_row_as_the_replaceable_node
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector('div.data-table-component > div[data-bulk-actions-target="toolbar"]')
  end

  def test_bulk_actions_bar_is_a_sibling_of_the_toolbar_and_not_nested_in_it
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_selector("div.data-table-component > div.bulk-actions-component")
    assert_no_selector('[data-bulk-actions-target="toolbar"] .bulk-actions-component')
  end

  def test_bulk_actions_alone_does_not_bring_up_the_toolbar_row
    # The contextual bar does NOT live in the toolbar's row: with no other control declared there is
    # no toolbar to hide.
    render_inline(component) do |c|
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector('[data-bulk-actions-target="toolbar"]')
    assert_selector("div.bulk-actions-component")
  end

  # --- Toolbar overflow: the ⋯ of narrow viewports ---

  # Filters (70, survive) + columns (35, collapses): the minimum case with something on each
  # side of the threshold.
  def render_collapsible_toolbar
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  # All three groups populated: the view's content (left), how it is remembered (memory) and how
  # it looks (right). The form carries a storage_id, so the persistence checkbox paints too. The
  # view switch is the ONLY thing populating the right since the export moved into the
  # PageHeader's ⋯.
  def render_full_toolbar
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: saved_views_form)) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_saved_views
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      declare_views(c)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  # The ColumnSelector has no test of its own: its coverage lives here.
  # The negative assertion MUST be scoped to the `data-controller`: the toolbar's own ⋯ is
  # painted with `align: :bottom_end`, so a bare `assert_no_selector('.dropdown-end')` fails
  # against a `dropdown-end` that is correct and has to stay.
  def test_the_column_selector_popover_opens_to_the_left
    render_collapsible_toolbar

    assert_selector("[data-controller='column-selector'].dropdown", visible: :all)
    assert_no_selector("[data-controller='column-selector'].dropdown-end", visible: :all)
  end

  def test_toolbar_declares_the_overflow_controller_and_a_home_group_per_family
    render_full_toolbar

    assert_selector('div[data-controller~="toolbar-overflow"]', visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="left"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="memory"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="right"]',
                    count: 1, visible: :all)
    # With no host buttons there is no host group: an empty group is a flex item that takes the
    # row's `gap` on both of its sides.
    assert_no_selector('[data-toolbar-overflow-group="host"]', visible: :all)
  end

  def test_the_left_group_reads_filters_then_group_by_then_columns
    # On expand the JS reorders each group by DESCENDING priority, so these numbers and not the
    # template are what fix the row's order: read from highest to lowest they have to give the
    # order asked for.
    form = GroupableDataTableFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    priorities = page.all('[data-toolbar-overflow-group="left"][data-toolbar-overflow-target="item"]',
                          visible: :all).map { |item| item["data-toolbar-overflow-priority"].to_i }

    assert_equal [ 70, 40, 35 ], priorities
  end

  def test_the_memory_group_reads_saved_views_then_the_persistence_bookmark
    render_full_toolbar

    priorities = page.all('[data-toolbar-overflow-group="memory"][data-toolbar-overflow-target="item"]',
                          visible: :all).map { |item| item["data-toolbar-overflow-priority"].to_i }

    assert_equal [ 30, 25 ], priorities
  end

  def test_the_column_selector_collapses_from_the_left_group
    render_full_toolbar

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="35"]', count: 1, visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="35"]',
                       visible: :all)
  end

  def test_the_separator_is_not_a_control
    # Marked as an `item` it would travel into the ⋯ as if it were a control, and with a priority
    # the JS would reorder it among the group's controls. It is neither of those things.
    render_full_toolbar

    assert_selector('[data-toolbar-overflow-target="separator"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-separates="left memory"]', count: 1, visible: :all)
    assert_no_selector("[data-toolbar-overflow-separates][data-toolbar-overflow-priority]",
                       visible: :all)
    assert_no_selector('[data-toolbar-overflow-separates][data-toolbar-overflow-target~="item"]',
                       visible: :all)
    # A sibling of the two groups, a child of neither: inside one, the JS pushes it to the end.
    assert_no_selector('[data-toolbar-overflow-target="group"] [data-toolbar-overflow-target="separator"]',
                       visible: :all)
  end

  def test_the_separator_is_served_hidden_below_the_breakpoint
    # The no-JS case: below `sm` nobody is left to its right to hold it up.
    render_full_toolbar

    assert_selector('[data-toolbar-overflow-target="separator"][class~="max-sm:hidden"]', visible: :all)
  end

  def test_no_separator_without_something_on_both_sides
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector('[data-toolbar-overflow-target="separator"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="memory"]', visible: :all)
  end

  def test_no_separator_with_only_the_memory_side
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: saved_views_form)) do |c|
      c.with_saved_views
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-group="memory"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="separator"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="left"]', visible: :all)
  end

  def test_only_the_view_switch_stays_on_the_right
    render_full_toolbar

    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="30"]',
                       visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="25"]',
                       visible: :all)
  end

  def test_host_buttons_get_their_own_group_and_leave_the_view_switch_pinned_right
    # Inside the right group the JS ordered them by DESCENDING priority (10 against 50) and the
    # host's button ended up to the right of the view switch — which is the only thing allowed
    # against the edge, because it is the only thing that says how the listing LOOKS.
    render_inline(component) do |c|
      declare_views(c)
      c.with_toolbar_button { '<button class="btn">Refresh</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="group"][data-toolbar-overflow-group="host"]',
                    count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-group="host"][data-toolbar-overflow-priority="10"]',
                    count: 1, visible: :all)
    assert_no_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="10"]',
                       visible: :all)
    assert_selector('[data-toolbar-overflow-group="right"][data-toolbar-overflow-priority="50"]',
                    count: 1, visible: :all)
  end

  def test_collapsible_controls_declare_their_priority_and_home_group
    render_collapsible_toolbar

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="70"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="35"]', count: 1, visible: :all)
  end

  def test_toolbar_controls_exist_exactly_once_in_the_dom
    # THE overflow contract: the JS MOVES nodes. Without this test the old pattern
    # (`hidden md:block` + a mobile copy) can come back without anything failing — and two copies
    # of the column selector are two controllers driving the same table.
    render_collapsible_toolbar

    assert_selector('[data-toolbar-overflow-target="item"]', count: 2, visible: :all)
    assert_selector("div.filters", count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-target="menu"]', count: 1, visible: :all)
    # The landing zone is served EMPTY: the JS fills it on collapse.
    assert_no_selector('[data-toolbar-overflow-target="menu"] *', visible: :all)
  end

  def test_overflow_menu_is_served_hidden_and_revealed_by_the_javascript
    # Served with `hidden` and revealed by the JS when it moves the first control inside: that way
    # a ⋯ that opens an empty menu does not flash while the bundle loads.
    #
    # No `sm:hidden`, deliberately: the breakpoint no longer decides the collapse, it is MEASURED
    # (`max-content` against the row's real width), so the ⋯ has to be able to appear at any
    # width — with a sidebar, a 1024px window leaves the toolbar without room long before
    # reaching `sm`. A class hiding it above 640px would make it unreachable exactly where it is
    # needed most.
    render_collapsible_toolbar

    assert_selector('[data-toolbar-overflow-target="overflow"][class~="hidden"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="overflow"][class~="sm:hidden"]', visible: :all)
  end

  def test_collapsible_controls_mark_their_label_for_the_overflow_menu
    # Contract with data_table/index.css: the controls hide their label below `sm` so they do not
    # eat the row, and inside the ⋯ —where width is plentiful— it comes back. Without both
    # classes the menu is left with anonymous icons, and no CSS test sees that.
    form = GroupableDataTableFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="menu"].toolbar-overflow-menu', visible: :all)
    assert_selector('[data-toolbar-overflow-priority="35"] span.toolbar-control-label',
                    text: "Columns", visible: :all)
    assert_selector('[data-toolbar-overflow-priority="40"] span.toolbar-control-label',
                    text: "Group by", visible: :all)
  end

  def test_overflow_menu_is_not_rendered_without_collapsible_controls
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="menu"]', visible: :all)
  end

  def test_view_switch_does_not_open_the_overflow_menu_by_itself
    # Priority 50 = the threshold: the switch SHRINKS (icon_only responsive), it does not collapse.
    # If it opened the ⋯ while being the only extra declared, the menu would come out empty.
    render_inline(component) do |c|
      declare_views(c)
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-priority="50"]',
                    count: 1, visible: :all)
    assert_no_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_view_switch_collapses_its_labels_below_the_breakpoint
    render_inline(component) do |c|
      declare_views(c)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # The label collapses through CSS, but the accessible name always travels: on mobile the
    # button is left with an icon only.
    assert_selector("a[title='Tabla'][aria-label='Tabla']")
    assert_selector("a[href*='view=table'] span[class~='max-sm:hidden']", text: "Tabla")
  end

  def test_group_by_control_collapses_from_the_left_group
    form = GroupableDataTableFilterForm.new(Movie.all, ActionController::Parameters.new({}))
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: form)) do |c|
      c.with_filters_panel
      c.with_table { "".html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="left"]' \
                    '[data-toolbar-overflow-priority="40"]', count: 1, visible: :all)
    assert_selector('[data-toolbar-overflow-priority="40"] span.toolbar-control-label', visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_each_toolbar_button_gets_its_own_collapsible_wrapper
    render_inline(component) do |c|
      c.with_toolbar_button { '<button class="btn">A</button>'.html_safe }
      c.with_toolbar_button { '<button class="btn">B</button>'.html_safe }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('[data-toolbar-overflow-target="item"][data-toolbar-overflow-group="host"]' \
                    '[data-toolbar-overflow-priority="10"]', count: 2, visible: :all)
    assert_selector('[data-toolbar-overflow-target="overflow"]', visible: :all)
  end

  def test_toolbar_row_keeps_the_overflow_controller_and_the_bulk_actions_target
    # Both live in the SAME row: the contextual bar hides it whole, the overflow rearranges what
    # is inside. Writing the `data` hash instead of merging into it wiped the controller without
    # failing anywhere.
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_column_selector { |cs| cs.with_column(index: 0, label: "Name") }
      c.with_bulk_actions { |bulk| bulk.with_action(label: "Delete", href: "/delete") }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector('div[data-controller~="toolbar-overflow"][data-bulk-actions-target="toolbar"]',
                    visible: :all)
  end

  def test_filters_panel_preserves_the_declared_display_mode_as_hidden_field
    # The filters submit rebuilds the URL from `url:`, which the host passes WITHOUT a query
    # string: without this hidden field, filtering while in cards sent the user back to the table.
    @options = { display_mode: :grid }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
  end

  def test_simple_filters_preserve_the_declared_display_mode_as_hidden_field
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form,
                                                 display_mode: :grid)) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
    assert_selector("form input[type=hidden][name=group_by][value=genre]", visible: :all)
  end

  def test_no_view_hidden_field_when_the_host_declares_no_display_mode
    # A listing with no view switch has no business writing `view=table` into the URL.
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector("input[type=hidden][name=view]", visible: :all)
  end

  def test_the_preserved_view_field_follows_view_param
    @options = { display_mode: :grid, view_param: :mode }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=mode][value=grid]", visible: :all)
    assert_no_selector("input[type=hidden][name=view]", visible: :all)
  end

  def test_explicit_preserved_params_do_not_drop_the_active_view
    @options = { display_mode: :grid }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes, preserved_params: { tab: "archived" })
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
    assert_selector("form input[type=hidden][name=tab][value=archived]", visible: :all)
  end

  def test_simple_filters_explicit_preserved_params_do_not_drop_the_active_view
    @options = { display_mode: :grid, filter_form: grouping_filter_form(view: "grid") }
    render_inline(component) do |c|
      c.with_simple_filters(preserved_params: { tab: "archived" })
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("form input[type=hidden][name=view][value=grid]", visible: :all)
    assert_selector("form input[type=hidden][name=tab][value=archived]", visible: :all)
  end

  def test_a_nested_view_param_does_not_blow_up_the_component
    # `display_mode:` usually arrives straight from params[:view]; `?view[]=x` does not respond to
    # to_sym and blew up the whole render before it ever reached the gate.
    @options = { display_mode: [ "grid" ] }
    render_inline(component) do |c|
      c.with_view_switch { |vs| vs.with_view(name: "Table", icon: "list", value: :table) }
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_selector("div.data-table-component")
    assert_selector('.view-switch-component a[aria-current="page"]', text: "Table")
  end

  def test_actions_panel_is_gone
    # The whole panel died: with_view_switch replaces its grid/table toggle, the PageHeader's ⋯
    # its export (page.with_export) and with_bulk_actions its actions slot. Breaking loudly beats
    # going on painting the path of #653.
    refute_respond_to(component, :with_actions_panel)
    refute(Bali::DataTable.const_defined?(:ActionsPanel))
  end

  def test_export_is_not_a_toolbar_slot
    # The export moved into the PageHeader's ⋯ (`page.with_export`): exporting is an action ON the
    # page, not a control of how the listing looks. `dt.with_export` has to raise NoMethodError
    # and not go on painting a button that ignores the filters.
    refute_respond_to(component, :with_export)
    refute(Bali::DataTable::Component::OVERFLOW_PRIORITIES.key?(:export))
  end

  # --- footer ---------------------------------------------------------------------------
  #
  # The footer is no longer drawn here: it is the SAME PaginationFooter any host can render on its
  # own. What these tests pin is that the listing keeps producing the summary and the controls,
  # and keeps producing them exactly ONCE.

  def render_with_pagy(pagy, **options)
    @options = options.merge(pagy: pagy)
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
      yield c if block_given?
    end
  end

  def test_footer_renders_the_summary_and_the_controls
    render_with_pagy(Pagy::Offset.new(count: 47, page: 2, limit: 10), item_name: "movies")

    assert_text("Showing 11-20 of 47 movies")
    assert_selector("nav.pagy-nav-daisyui .join")
  end

  def test_footer_summary_is_emitted_once
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10), item_name: "movies")

    assert_equal 1, page.text.scan("Showing 1-10 of 47 movies").size
  end

  # Characterisation test: the LITERAL class list the listing's footer had in 3.0, when it was
  # drawn inline here. Moving the footer into PaginationFooter cannot change a pixel of the
  # table's foot, and the first version of that change did move it: the standalone footer's `py-4`
  # added to the listing's `pt-4` and put 16px of bottom padding where there had been none. If
  # this string changes, change it on purpose and write down why.
  FOOTER_CLASSES_ON_3_0 =
    "flex flex-col sm:flex-row items-center justify-between gap-4 mt-4 pt-4 border-t border-base-200"

  def test_footer_keeps_the_exact_box_it_had_when_it_was_inline
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10), item_name: "movies")

    footer = page.find("div.data-table-component > div:last-child")
    assert_equal FOOTER_CLASSES_ON_3_0.split.sort, footer[:class].split.sort
  end

  def test_footer_falls_back_to_the_shared_item_name
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10))

    assert_text("Showing 1-10 of 47 items")
  end

  def test_footer_picks_the_singular_from_a_hash_item_name
    render_with_pagy(Pagy::Offset.new(count: 1, page: 1, limit: 10),
      item_name: { one: "movie", other: "movies" })

    assert_text("Showing 1-1 of 1 movie")
  end

  # With zero results the listing said "Showing 0-0 of 0 movies" underneath an empty table.
  def test_footer_says_nothing_without_results
    render_with_pagy(Pagy::Offset.new(count: 0, page: 1, limit: 10), item_name: "movies")

    assert_no_text("Showing")
    assert_no_selector(".border-t")
  end

  def test_top_summary_says_nothing_without_results
    render_with_pagy(Pagy::Offset.new(count: 0, page: 1, limit: 10),
      item_name: "movies", summary_position: :top)

    assert_no_text("Showing")
  end

  def test_top_summary_replaces_the_footer_one
    render_with_pagy(Pagy::Offset.new(count: 47, page: 1, limit: 10),
      item_name: "movies", summary_position: :top)

    assert_equal 1, page.text.scan("Showing 1-10 of 47 movies").size
  end

  def test_custom_pagy_nav_replaces_the_controls
    render_with_pagy(Pagy::Offset.new(count: 47, page: 2, limit: 10)) do |c|
      c.with_custom_pagy_nav { '<nav class="my-nav"></nav>'.html_safe }
    end

    assert_selector("nav.my-nav")
    assert_no_selector("nav.pagy-nav-daisyui")
    assert_text("Showing 11-20 of 47 items")
  end

  def test_no_footer_without_a_pagy
    render_inline(component) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    assert_no_selector(".border-t")
    assert_no_text("Showing")
  end

  # --- page links ---------------------------------------------------------------------------
  #
  # Who builds the URL for "page 2" depends on whether the Pagy carries a request, and the listing
  # does not take the work off Pagy when Pagy can do it: a DataTable's `url:` is the filtering and
  # sorting base, which the host passes WITHOUT a query string, so making it win wipes the applied
  # narrowing when the page changes (#756).

  def render_listing(pagy:, url: "/movies")
    render_inline(Bali::DataTable::Component.new(url: url, pagy: pagy)) do |c|
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
  end

  def linkable_pagy(params:, path: "/admin/movies")
    request = Pagy::Request.new(
      request: { base_url: "http://example.com", path: path, params: params, cookie: nil }
    )
    Pagy::Offset.new(count: 47, page: 1, limit: 10, request: request)
  end

  def page_link_href(number)
    page.find("nav.pagy-nav-daisyui a", text: number.to_s, exact_text: true)[:href]
  end

  def test_page_links_point_at_the_listing_url_when_the_pagy_has_no_request
    render_listing(pagy: Pagy::Offset.new(count: 47, page: 1, limit: 10))

    assert_equal "/movies?page=2", page_link_href(2)
  end

  # With no base, a request-less Pagy fell back to a bare `?page=2`, and that href REPLACES the
  # browser's whole query string: the filter the user was looking at disappeared on turning the
  # page. The listing builds the base the same way the view switch and "Group by" do.
  def test_page_links_keep_the_applied_filter_when_the_pagy_has_no_request
    with_request_url "/admin/movies?q%5Bname_cont%5D=a&page=1" do
      render_listing(pagy: Pagy::Offset.new(count: 47, page: 1, limit: 10))
    end

    assert_equal "/movies?q%5Bname_cont%5D=a&page=2", page_link_href(2)
  end

  # THE regression the naive fix introduces. With the `pagy()` helper —that is, in any host— the
  # Pagy builds its URLs from the real request, narrowing included; handing it the listing's
  # `url:` would overwrite that (PagyAdapter#page_url, #654) and return `/?page=2`.
  def test_a_linkable_pagy_keeps_building_its_own_page_links
    render_listing(pagy: linkable_pagy(params: { "q" => { "name_cont" => "a" } }), url: "/")

    assert_equal "/admin/movies?q%5Bname_cont%5D=a&page=2", page_link_href(2)
  end
end
