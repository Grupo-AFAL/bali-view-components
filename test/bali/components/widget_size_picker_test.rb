# frozen_string_literal: true

require "test_helper"

class BaliWidgetSizePickerComponentTest < ComponentTestCase
  def picker(size: :medium)
    Bali::Widget::SizePicker::Component.new(size: size, title: "Low stock")
  end

  def test_renders_a_radio_per_size_with_the_current_one_checked
    render_inline(picker(size: :large))

    assert_selector("[role='radiogroup']", visible: :all)
    assert_selector("button[role='radio'][data-widget-size]", count: 3, visible: :all)
    assert_selector("button[data-widget-size='large'][aria-checked='true']", visible: :all)
    assert_selector("button[data-widget-size='small'][aria-checked='false']", visible: :all)
  end

  # The four sizes are mutually exclusive, so the whole group is ONE tab stop and
  # the checked size carries it. Without this a keyboard user crosses three
  # buttons per card — 48 stops in a twelve-card grid — to reach the next card.
  def test_is_one_tab_stop_carried_by_the_checked_size
    render_inline(picker(size: :large))

    assert_selector("button[data-widget-size='large'][tabindex='0']", visible: :all)
    assert_selector("button[data-widget-size][tabindex='-1']", count: 2, visible: :all)
  end

  # Selection follows focus, so the arrows must reach the controller rather than
  # scrolling the page. Bound on the GROUP: the handler needs the whole set to
  # know what "next" means.
  def test_routes_arrow_keys_to_the_grid_controller
    render_inline(picker)

    assert_selector(
      "[role='radiogroup'][data-action='keydown->bali-widget-grid#sizeKeydown']", visible: :all
    )
  end

  # A dashboard has twelve of these; the group has to say which card it sizes.
  def test_names_the_widget_it_sizes
    render_inline(picker)

    assert_selector("[role='radiogroup'][aria-label='Size of Low stock']", visible: :all)
  end

  # The lattice is the point, not the fill: four rectangles floating in
  # whitespace have no shared origin, which is why `medium` and `large` were
  # indistinguishable at the same width.
  def test_draws_each_size_as_a_filled_lattice_over_eight_cells
    render_inline(picker)

    assert_selector("button[data-widget-size='large'] span[aria-hidden='true'] > span",
                    count: 8, visible: :all)
  end

  def test_cell_class_marks_the_filled_cells_of_each_size
    component = picker

    assert_includes component.send(:cell_class, :large, 5), "bg-base-content/45"
    assert_includes component.send(:cell_class, :large, 2), "bg-base-content/20"
  end
end
