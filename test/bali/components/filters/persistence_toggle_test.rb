# frozen_string_literal: true

require "test_helper"

class BaliFiltersPersistenceToggleTest < ComponentTestCase
  def test_does_not_render_without_a_storage_id
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: nil))

    assert_no_selector('[data-controller="filter-persistence"]')
  end

  def test_renders_the_controller_with_the_storage_id
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector('[data-controller="filter-persistence"]')
    assert_selector('[data-filter-persistence-storage-id-value="movies"]')
    assert_selector('[data-filter-persistence-enabled-value="false"]')
  end

  # Los tooltips van en el elemento del CONTROLLER, no en el botón: el Stimulus los lee de
  # this.element y en el hijo eran invisibles — el texto caía al fallback en inglés.
  def test_tooltips_travel_as_values_on_the_controller_element
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector(
      '[data-controller="filter-persistence"][data-filter-persistence-enabled-tooltip-value]' \
      "[data-filter-persistence-disabled-tooltip-value]"
    )
    assert_no_selector("button[data-filter-persistence-enabled-tooltip-value]")
  end

  def test_shows_the_disabled_icon_by_default
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector('[data-filter-persistence-target="iconDisabled"]:not(.hidden)')
    assert_selector('[data-filter-persistence-target="iconEnabled"].hidden')
  end

  def test_shows_the_enabled_icon_when_enabled
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies", enabled: true))

    assert_selector('[data-filter-persistence-target="iconEnabled"]:not(.hidden)')
    assert_selector('[data-filter-persistence-target="iconDisabled"].hidden')
    assert_selector('[data-filter-persistence-enabled-value="true"]')
  end

  # Los dos íconos son svg `aria-hidden` y `data-tip` es invisible para un lector de pantalla:
  # sin aria-label el botón no tiene nombre accesible.
  def test_the_button_has_an_accessible_name
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector('button[data-action="filter-persistence#toggle"][aria-label="Remember filters"]')
  end

  # El nombre no cambia con el estado, los íconos son `aria-hidden` y `data-tip` es contenido
  # generado por CSS: `aria-pressed` es lo único que le dice a un lector de pantalla si los
  # filtros se están recordando o no. Sin él el botón se anuncia igual en los dos estados.
  def test_the_button_announces_its_state
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector('button[data-action="filter-persistence#toggle"][aria-pressed="false"]')
  end

  def test_the_button_announces_the_enabled_state
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies", enabled: true))

    assert_selector('button[data-action="filter-persistence#toggle"][aria-pressed="true"]')
  end

  # CONTRATO de data_table/index.css: sin esta clase el control queda como un ícono anónimo
  # dentro del menú ⋯.
  def test_the_label_carries_the_toolbar_control_label_class
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector("span.toolbar-control-label", text: "Remember filters")
  end
end
