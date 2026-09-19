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

  # The tooltips go on the CONTROLLER's element, not on the button: Stimulus reads them from
  # this.element and on the child they were invisible — the text fell back to the English default.
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

  # Both icons are `aria-hidden` svgs and `data-tip` is invisible to a screen reader: without an
  # aria-label the button has no accessible name.
  def test_the_button_has_an_accessible_name
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector('button[data-action="filter-persistence#toggle"][aria-label="Remember filters"]')
  end

  # The name does not change with the state, the icons are `aria-hidden` and `data-tip` is
  # CSS-generated content: `aria-pressed` is the only thing telling a screen reader whether the
  # filters are being remembered. Without it the button announces the same in both states.
  def test_the_button_announces_its_state
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector('button[data-action="filter-persistence#toggle"][aria-pressed="false"]')
  end

  def test_the_button_announces_the_enabled_state
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies", enabled: true))

    assert_selector('button[data-action="filter-persistence#toggle"][aria-pressed="true"]')
  end

  # CONTRACT with data_table/index.css: without this class the control is an anonymous icon inside
  # the ⋯ menu.
  def test_the_label_carries_the_toolbar_control_label_class
    render_inline(Bali::Filters::PersistenceToggle::Component.new(storage_id: "movies"))

    assert_selector("span.toolbar-control-label", text: "Remember filters")
  end
end
