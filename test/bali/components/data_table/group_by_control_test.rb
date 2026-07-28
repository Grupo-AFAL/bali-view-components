# frozen_string_literal: true

require "test_helper"

class BaliDataTableGroupByControlComponentTest < ComponentTestCase
  # Minimal stand-in for the slice of FilterForm the control consumes.
  class FilterFormStub
    def initialize(options:, active: false, group_by: nil)
      @options = options
      @active = active
      @group_by = group_by
    end

    def group_by_options = @options
    def group_by_active? = @active
    def group_by = @group_by
  end

  OPTIONS = [
    { attribute: :genre, label: "Género" },
    { attribute: :status, label: "Status" }
  ].freeze

  def component(active: false, group_by: nil, current_params: {})
    Bali::DataTable::GroupByControl::Component.new(
      url: "/movies",
      filter_form: FilterFormStub.new(options: OPTIONS, active: active, group_by: group_by),
      current_params: current_params
    )
  end

  def test_does_not_render_without_options
    stub = FilterFormStub.new(options: [])
    render_inline(Bali::DataTable::GroupByControl::Component.new(url: "/movies", filter_form: stub))
    assert_no_selector(".dropdown")
  end

  def test_renders_dropdown_with_an_option_link_per_attribute
    render_inline(component)
    assert_selector(".dropdown")
    assert_selector("a[href*='group_by=genre']")
    assert_selector("a[href*='group_by=status']")
  end

  def test_renders_no_grouping_option_that_removes_the_param
    render_inline(component(active: true, group_by: :genre))
    no_group = page.find("a", text: "No grouping")
    refute_includes(no_group[:href], "group_by")
  end

  def test_option_links_preserve_existing_query_params
    current_params = { "q" => { "genre_eq" => "action" }, "page" => "3" }
    render_inline(component(current_params: current_params))
    # Active filter param survives in the merged link
    assert_selector("a[href*='group_by=genre'][href*='genre_eq']")
  end

  def test_option_links_reset_pagination
    render_inline(component(current_params: { "page" => "3", "q" => { "genre_eq" => "action" } }))
    assert_no_selector("a[href*='page=3']")
  end

  def test_trigger_shows_current_selection_when_active
    render_inline(component(active: true, group_by: :genre))
    assert_text("Group by: Género")
  end

  def test_trigger_shows_default_label_when_inactive
    render_inline(component)
    assert_text("Group by")
  end

  def test_localizes_labels_in_spanish
    I18n.with_locale(:es) do
      render_inline(component)
      assert_text("Agrupar por")
      assert_selector("a", text: "Sin agrupar")
    end
  end

  # --- R5: opciones explícitas (superficies sin FilterForm, p.ej. el Gantt) ---

  def test_explicit_options_render_without_a_filter_form
    render_inline(Bali::DataTable::GroupByControl::Component.new(
      url: "/projects", current_params: { "data_display_mode" => "gantt" },
      options: [ { attribute: "program", label: "Programa" }, { attribute: "area", label: "Área" } ],
      current: "program", param: "gantt_group_by", include_none: false
    ))

    # El param propio viaja en los hrefs, conservando los params ajenos.
    assert_selector "a[href='/projects?data_display_mode=gantt&gantt_group_by=area']", text: "Área"
    # La opción activa nombra el trigger.
    assert_text "Group by: Programa"
    # include_none: false — no hay item "sin agrupar".
    assert_no_selector "a[href='/projects?data_display_mode=gantt']"
  end

  def test_explicit_options_win_over_the_filter_form
    render_inline(Bali::DataTable::GroupByControl::Component.new(
      url: "/movies",
      filter_form: FilterFormStub.new(options: OPTIONS, active: true, group_by: :genre),
      options: [ { attribute: "year", label: "Año" } ], current: "year"
    ))

    assert_selector "a", text: "Año"
    assert_no_selector "a", text: "Género"
  end
end
