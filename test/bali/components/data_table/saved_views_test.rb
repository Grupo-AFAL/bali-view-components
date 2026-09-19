# frozen_string_literal: true

require "test_helper"

class BaliDataTableSavedViewsComponentTest < ComponentTestCase
  FakeStore = Struct.new(:views) do
    def list = views
    def find(id) = views.find { |view| view.id.to_s == id.to_s }
  end

  SavedView = Struct.new(:id, :name, :payload, keyword_init: true)

  def store
    @store ||= FakeStore.new([
      SavedView.new(id: 1, name: "Activos", payload: { "attributes" => { "name_i_cont" => "a" } }),
      SavedView.new(id: 2, name: "Míos", payload: { "attributes" => {} })
    ])
  end

  def form(params = ActionController::Parameters.new, views_store: store)
    Bali::FilterForm.new(Movie.all, params, saved_views_store: views_store)
  end

  def render_component(filter_form, **options)
    render_inline(Bali::DataTable::SavedViews::Component.new(
      filter_form: filter_form, url: "/vistas", base_url: "/listado", **options
    ))
  end

  def test_does_not_render_without_a_store
    render_component(Bali::FilterForm.new(Movie.all, ActionController::Parameters.new))
    assert_no_selector "[data-controller='saved-views']"
  end

  def test_the_popover_opens_to_the_left_now_that_the_control_lives_on_the_left
    # Anchored to the right edge of its trigger (`dropdown-end`) the panel opened away from the row
    # it belongs to, ever since the control moved into the left group.
    render_component(form)

    assert_selector "[data-controller='saved-views'].dropdown"
    assert_no_selector "[data-controller='saved-views'].dropdown-end"
  end

  def test_renders_personal_views_with_apply_urls_and_the_save_form
    render_component(form)

    assert_selector "[data-controller='saved-views']"
    assert_selector "a[href='/listado?saved_view=1']", text: "Activos"
    assert_selector "a[href='/listado?saved_view=2']", text: "Míos"
    # The save form: POST to the app's URL with the payload serialised in a hidden field.
    assert_selector "form[action='/vistas'] input[name='payload']", visible: :all
    # Rename/delete point at the resource's route.
    assert_selector "form[action='/vistas/1']", visible: :all
  end

  def test_the_button_shows_the_applied_view_name
    applied = form(ActionController::Parameters.new(saved_view: "1"))
    render_component(applied)

    assert_selector "button", text: "Activos"
    assert_selector "a[href='/listado?saved_view=1'].text-primary"
  end

  def test_default_views_render_in_their_own_suggested_section
    render_component(form, default_views: [ { name: "En riesgo", url: "/listado?q%5Bhealth_eq%5D=rojo" } ])

    assert_selector "a[href='/listado?q%5Bhealth_eq%5D=rojo']", text: "En riesgo"
  end

  def test_base_url_with_existing_query_appends_with_ampersand
    render_inline(Bali::DataTable::SavedViews::Component.new(
      filter_form: form, url: "/vistas", base_url: "/listado?vista=tabla"
    ))

    assert_selector "a[href='/listado?vista=tabla&saved_view=1']"
  end

  # --- The engine's default store (saved_views_store: :default) ---

  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def default_form
    Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                         storage_id: "movies_index", saved_views_store: :default,
                         saved_views_owner: owner)
  end

  def test_default_store_resolves_to_the_engine_storage_scoped_to_the_owner
    Bali::SavedView.create!(owner: owner, storage_id: "movies_index", name: "Guardada",
                            payload: { "attributes" => {} })
    Bali::SavedView.create!(owner: User.create!(name: "Otra"), storage_id: "movies_index",
                            name: "Ajena", payload: { "attributes" => {} })

    form = default_form

    assert_predicate form, :saved_views_enabled?
    assert_equal [ "Guardada" ], form.saved_views.map(&:name)
  end

  def test_default_store_needs_owner_and_storage_id_or_stays_off
    no_owner = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                    storage_id: "movies_index", saved_views_store: :default)
    no_storage = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                      saved_views_store: :default,
                                      saved_views_owner: User.create!(name: "Beto"))

    assert_not no_owner.saved_views_enabled?
    assert_not no_storage.saved_views_enabled?
  end

  def test_the_data_table_slot_defaults_the_url_to_the_engine_routes
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: default_form)) do |dt|
      dt.with_saved_views
      dt.with_table { "".html_safe }
    end

    # The save form POSTs against the mounted engine's routes, with the FilterForm's own storage_id
    # in the query string.
    assert_selector "form[action='/bali/saved_views?storage_id=movies_index']", visible: :all
  end

  def test_saved_views_and_the_column_selector_agree_on_the_listing_target
    # The saved-views JS finds the column selector by comparing THIS exact string, and reads its
    # stored columns from THIS key: if the two derivations drift apart, saving a view loses the
    # columns without failing anywhere.
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: default_form)) do |dt|
      dt.with_saved_views
      dt.with_column_selector { |cs| cs.with_column(index: 0, label: "Nombre") }
      dt.with_table { "".html_safe }
    end

    assert_selector "[data-saved-views-table-value='#movies_index table']"
    assert_selector "[data-column-selector-table-value='#movies_index table']"
    assert_selector "[data-saved-views-storage-key-value='bali:columns:movies_index']"
    assert_selector "[data-column-selector-storage-key-value='bali:columns:movies_index']"
  end

  def test_applying_a_view_keeps_the_current_display_mode
    # The view switch preserves `saved_view` on purpose; the reverse direction has to be symmetric —
    # applying a view cannot take the user out of the mode they are looking at.
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form,
                                                 display_mode: :grid)) do |dt|
      dt.with_saved_views(url: "/vistas")
      dt.with_grid { "".html_safe }
    end

    assert_selector "a[href='/listado?view=grid&saved_view=1']"
  end

  def test_without_a_display_mode_the_apply_url_stays_bare
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form)) do |dt|
      dt.with_saved_views(url: "/vistas")
      dt.with_table { "".html_safe }
    end

    assert_selector "a[href='/listado?saved_view=1']"
  end

  def test_the_columns_imposed_by_the_applied_view_travel_to_the_controller
    # With no selector in the DOM (modes other than table) the JS fell back to localStorage, which is
    # the memory from BEFORE the view: saving from cards persisted columns the user was not looking
    # at.
    columns_store = FakeStore.new([
      SavedView.new(id: 5, name: "Compacta", payload: { "attributes" => {}, "columns" => [ 1, 3 ] })
    ])
    render_component(form(ActionController::Parameters.new(saved_view: "5"), views_store: columns_store))

    assert_selector "[data-saved-views-server-columns-value='[1,3]']"
  end

  def test_the_slot_without_url_nor_storage_id_does_not_render_the_dropdown
    form_without_storage = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new,
                                                saved_views_store: store)
    render_inline(Bali::DataTable::Component.new(url: "/listado", filter_form: form_without_storage)) do |dt|
      dt.with_saved_views
      dt.with_table { "".html_safe }
    end

    assert_no_selector "[data-controller='saved-views']"
  end

  # --- Active view by STATE match (persistence leaves the URL clean) ---

  class NamedMovieFilterForm < Bali::FilterForm
    attribute :name_i_cont, :string
  end

  def named_form(params = ActionController::Parameters.new, views_store: store)
    NamedMovieFilterForm.new(Movie.all, params, saved_views_store: views_store)
  end

  def test_a_personal_view_matching_the_current_state_is_active_without_the_url_param
    # The payload of "Activos" (name_i_cont: "a") describes the form's current state even when the
    # URL carries no ?saved_view — exactly what happens after a persistence restore or when
    # navigating back.
    matching = named_form(ActionController::Parameters.new(q: { name_i_cont: "a" }))
    render_component(matching)

    assert_selector "a[href='/listado?saved_view=1'].text-primary"
    assert_selector "button", text: "Activos"
  end

  def test_a_default_view_whose_query_matches_the_state_is_active
    only_defaults = named_form(ActionController::Parameters.new(q: { name_i_cont: "a" }),
                               views_store: FakeStore.new([]))
    render_component(only_defaults,
                     default_views: [ { name: "Con a", url: "/listado?q%5Bname_i_cont%5D=a" },
                                      { name: "Otra", url: "/listado?q%5Bname_i_cont%5D=z" } ])

    assert_selector "a.text-primary", text: "Con a"
    assert_no_selector "a.text-primary", text: "Otra"
    assert_selector "button", text: "Con a"
  end

  def test_the_view_applied_by_url_wins_over_state_matching
    # An explicitly applied saved_view=2 wins the marker even when the state also matches another
    # view: one active view, no double marking.
    applied = named_form(ActionController::Parameters.new(saved_view: "2"))
    render_component(applied)

    assert_selector "a[href='/listado?saved_view=2'].text-primary"
    assert_no_selector "a[href='/listado?saved_view=1'].text-primary"
    assert_selector "button", text: "Míos"
  end

  # --- The active marker cannot LIE ---

  def test_a_view_whose_payload_normalizes_to_empty_never_matches_by_state
    # B2's flagship case ("I save my column arrangement"): a payload with no filters. It describes
    # the clean state, so it matched on EVERY visit and marked itself active even though its columns
    # were not applied (columns only apply with ?saved_view=).
    columns_only = FakeStore.new([
      SavedView.new(id: 9, name: "Compacta", payload: { "attributes" => {}, "columns" => [ 0, 1 ] })
    ])
    render_component(named_form(ActionController::Parameters.new, views_store: columns_only))

    assert_no_selector "a.text-primary"
    # The button keeps its generic label: there is no view to name.
    assert_selector "button", text: I18n.t("bali_view.data_table.saved_views.button_label")

    # Applied by URL it is recognised: there the view's state really is imposed.
    render_component(named_form(ActionController::Parameters.new(saved_view: "9"),
                                views_store: columns_only))
    assert_selector "a[href='/listado?saved_view=9'].text-primary"
  end

  def test_a_shortcut_stays_marked_after_the_builder_round_trip_adds_the_default_m
    # The builder re-emits q[g][0][m]=or even when the shortcut's URL never carried it: without
    # normalising that no-op combinator, the shortcut lost its mark after one popover apply or search.
    state = ActionController::Parameters.new(q: { g: { "0" => { name_i_cont: "a", m: "or" } } })
    render_component(named_form(state, views_store: FakeStore.new([])),
                     default_views: [ { name: "Con a", url: "/listado?q%5Bg%5D%5B0%5D%5Bname_i_cont%5D=a" } ])

    assert_selector "a.text-primary", text: "Con a"
  end

  def test_a_shortcut_matches_on_the_groupings_shape_used_by_real_apps
    # Real shortcuts travel as q[g][0][attr_eq] (not as flat attributes).
    state = ActionController::Parameters.new(q: { g: { "0" => { name_i_cont: "rojo" } } })
    render_component(named_form(state, views_store: FakeStore.new([])),
                     default_views: [
                       { name: "En rojo", url: "/listado?q%5Bg%5D%5B0%5D%5Bname_i_cont%5D=rojo" },
                       { name: "Otro", url: "/listado?q%5Bg%5D%5B0%5D%5Bname_i_cont%5D=verde" }
                     ])

    assert_selector "a.text-primary", text: "En rojo"
    assert_no_selector "a.text-primary", text: "Otro"
  end

  def test_no_update_action_without_an_origin_view
    render_component(form)

    assert_no_selector "input[type='submit'][value^='Update']"
    assert_selector "button", text: "Save current view"
  end

  # With the view applied and the state UNTOUCHED there is nothing to update: offering it would
  # promise to save something that is already saved.
  # The payload goes in `groupings` and not in `attributes`: an UNdeclared attribute is discarded when
  # the view is applied (the FilterForm's safety gate), so the state would never match the payload
  # and the view would read as modified — an artefact of the fixture, not of the component.
  def origin_store
    FakeStore.new([
      SavedView.new(id: 7, name: "Rojos",
                    payload: { "groupings" => { "0" => { "name_i_cont" => "rojo" } } })
    ])
  end

  def test_no_update_action_when_the_state_still_matches_the_origin
    render_component(form(ActionController::Parameters.new(saved_view: "7"), views_store: origin_store))

    assert_no_selector "input[type='submit'][value^='Update']"
    assert_selector "button", text: "Save current view"
  end

  def test_a_drifted_origin_offers_updating_it_and_demotes_saving
    state = ActionController::Parameters.new(view_origin: "7", q: { g: { "0" => { name_i_cont: "verde" } } })
    render_component(form(state, views_store: origin_store))

    assert_selector "form[action='/vistas/7'] input[type='submit'][value='Update \"Rojos\"']"
    assert_selector "form[action='/vistas/7'] input[name='payload']", visible: :all
    assert_selector "button", text: "Save as new view"
  end

  # The update PATCH is destructive: it overwrites the saved configuration.
  def test_updating_a_view_asks_for_confirmation
    state = ActionController::Parameters.new(view_origin: "7", q: { g: { "0" => { name_i_cont: "verde" } } })
    render_component(form(state, views_store: origin_store))

    assert_selector "form[data-turbo-confirm*='Rojos']"
  end

  def test_a_missing_origin_view_degrades_to_saving
    render_component(form(ActionController::Parameters.new(view_origin: "999")))

    assert_no_selector "input[type='submit'][value^='Update']"
    assert_selector "button", text: "Save current view"
  end

  def test_renaming_inputs_get_unique_ids
    render_component(form)

    ids = page.native.css("input[type='text']").map { |input| input["id"] }.compact
    assert_equal ids.uniq.size, ids.size, "los ids de los inputs de nombre deben ser únicos"
  end

  # The shipped markup cannot depend on the host's configuration: the dropdown's three forms (rename,
  # update and save) declare Rails' builder, so they render the same with and without
  # `default_form_builder = Bali::FormBuilder` set by the host (#1137). Remove that `builder:` from
  # the view and `f.text_field` goes back to `div.control` and `f.submit` to a `<button>`, and this
  # comparison fails.
  def test_the_internal_forms_render_the_same_under_the_hosts_default_builder
    # The state that has drifted from its origin view is what leaves all three forms on screen.
    state = ActionController::Parameters.new(view_origin: "7", q: { g: { "0" => { name_i_cont: "verde" } } })
    with_rails_default = render_component(form(state, views_store: origin_store)).to_html
    with_bali_default = with_default_form_builder(Bali::FormBuilder) do
      render_component(form(state, views_store: origin_store)).to_html
    end

    assert_equal with_rails_default, with_bali_default

    # `page` is left holding the second render (the one under Bali's builder as the default): what
    # concretely got lost there was Rails' plain submit with its `name="commit"`, and the input went
    # out wrapped in the builder's `div.control`. `visible: :all` because the save form is born
    # hidden.
    assert_selector "form[action='/vistas/7'] input[type='submit'][name='commit']", visible: :all
    assert_no_selector "div.control", visible: :all
  end
end
