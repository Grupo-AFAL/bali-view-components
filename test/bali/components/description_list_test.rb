# frozen_string_literal: true

require "test_helper"

class BaliDescriptionListComponentTest < ComponentTestCase
  def render_list(**options)
    render_inline(Bali::DescriptionList::Component.new(**options)) do |c|
      c.with_item(label: "Name", value: "Juan Perez")
      c.with_item(label: "Email", value: "juan@example.com")
    end
  end

  def test_renders_a_dl_grid_of_div_wrapped_dt_dd_pairs
    render_list
    assert_selector("dl.grid.description-list-component")
    assert_selector("dl > div.description-list-item-component", count: 2)
    assert_selector("dl > div > dt", text: "Name")
    assert_selector("dl > div > dd", text: "Juan Perez")
  end

  def test_defaults_to_two_responsive_columns
    render_list
    assert_selector("dl[class*='grid-cols-1'][class*='sm:grid-cols-2']")
  end

  def test_renders_a_single_column
    render_list(columns: 1)
    assert_selector("dl[class*='grid-cols-1']")
    assert_no_selector("dl[class*='sm:grid-cols-2']")
  end

  def test_renders_three_responsive_columns
    render_list(columns: 3)
    assert_selector("dl[class*='sm:grid-cols-2'][class*='lg:grid-cols-3']")
  end

  def test_falls_back_to_two_columns_for_an_unknown_count
    render_list(columns: 7)
    assert_selector("dl[class*='grid-cols-1'][class*='sm:grid-cols-2']")
  end

  def test_stacked_layout_does_not_turn_the_item_into_a_grid
    render_list
    assert_no_selector("dl > div.grid")
  end

  def test_horizontal_layout_puts_term_and_value_side_by_side
    render_list(layout: :horizontal)
    assert_selector("dl > div.grid[class*='grid-cols-3']", count: 2)
    assert_selector("dl > div > dd[class*='col-span-2']", text: "Juan Perez")
  end

  def test_falls_back_to_stacked_for_an_unknown_layout
    render_list(layout: :sideways)
    assert_no_selector("dl > div.grid")
  end

  def test_renders_block_content_when_value_is_nil
    render_inline(Bali::DescriptionList::Component.new) do |c|
      c.with_item(label: "Status") { "Rich content" }
    end
    assert_selector("dd", text: "Rich content")
  end

  def test_prefers_value_over_block_content_when_both_provided
    render_inline(Bali::DescriptionList::Component.new) do |c|
      c.with_item(label: "Name", value: "From value") { "From block" }
    end
    assert_selector("dd", text: "From value")
    assert_no_text("From block")
  end

  def test_reuses_label_value_typography_on_dt_and_dd
    render_list
    assert_selector("dt.font-bold.text-xs", text: "Name")
    assert_selector("dd.min-h-6", text: "Juan Perez")
  end

  def test_merges_custom_classes_and_passes_attributes_through_on_the_dl
    render_inline(Bali::DescriptionList::Component.new(class: "custom-class", data: { testid: "dl" })) do |c|
      c.with_item(label: "Name", value: "Test")
    end
    assert_selector("dl.grid.custom-class[data-testid='dl']")
  end

  def test_merges_custom_classes_and_passes_attributes_through_on_items
    render_inline(Bali::DescriptionList::Component.new) do |c|
      c.with_item(label: "Name", value: "Test", class: "item-class", data: { testid: "item" })
    end
    assert_selector("dl > div.description-list-item-component.item-class[data-testid='item']")
  end
end
