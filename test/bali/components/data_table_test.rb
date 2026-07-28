# frozen_string_literal: true

require "test_helper"

# Form con agrupación declarada, para el round-trip de preserved_params.
class GroupableDataTableFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Género"

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

  def grouping_filter_form(group_by: "genre")
    Bali::FilterForm.new(
      Movie.all,
      ActionController::Parameters.new(q: ActionController::Parameters.new({}), group_by: group_by),
      simple_filters: [ { attribute: :genre, collection: [ %w[Action Action] ], blank: "All" } ],
      group_by_attributes: %i[genre status]
    )
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

  def test_no_group_by_hidden_field_when_grouping_inactive
    render_inline(Bali::DataTable::Component.new(url: "/movies", filter_form: grouping_filter_form(group_by: nil))) do |c|
      c.with_simple_filters
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end
    assert_no_selector("input[type=hidden][name=group_by]", visible: :all)
  end

  # --- R5: superficie propia para la toolbar y preservación de la agrupación ---

  def test_toolbar_class_lands_on_the_toolbar_row_next_to_the_base_classes
    @options = { toolbar_class: "rounded-box border p-4" }
    render_inline(component) do |c|
      c.with_filters_panel(available_attributes: filter_attributes)
      c.with_table { '<div class="table-component"></div>'.html_safe }
    end

    # Las clases extra van en la MISMA fila de la toolbar (la que contiene los filtros),
    # no en otro contenedor: un host las usa para darle superficie de card cuando el
    # contenido trae la suya.
    assert_selector("div.data-table-component > div.rounded-box.border div.filters")
    assert_selector("div.data-table-component > div.flex.items-center.rounded-box")
  end

  def test_explicit_preserved_params_do_not_drop_the_active_group_by
    # Antes eran excluyentes: un host que preservaba sus propios params tiraba la
    # agrupación en cada submit de filtros o búsqueda.
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
end
