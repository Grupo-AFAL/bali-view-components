# frozen_string_literal: true

require "test_helper"

class BaliColumnsComponentTest < ComponentTestCase
  def setup
    @component = Bali::Columns::Component.new
  end

  private

  def assert_has_class(css_class)
    assert_selector("[class*='#{css_class}']")
  end

  def refute_has_class(css_class)
    assert_no_selector("[class*='#{css_class}']")
  end

  public

  # === Basic rendering ===

  def test_renders_flex_container
    render_inline(@component) do |c|
      c.with_column { "First" }
      c.with_column { "Second" }
    end
    assert_has_class("flex")
  end

  def test_renders_column_divs
    render_inline(@component) do |c|
      c.with_column { "First" }
      c.with_column { "Second" }
    end
    assert_selector("[class*='md:flex-1']", count: 2)
  end

  # === Gap sizes ===

  def test_applies_default_gap_3
    render_inline(@component) do |c|
      c.with_column { "Content" }
    end
    assert_has_class("gap-3")
  end

  Bali::Columns::Component::GAPS.each do |gap_name, gap_class|
    define_method("test_applies_#{gap_class}_for_gap_#{gap_name}") do
      render_inline(Bali::Columns::Component.new(gap: gap_name)) do |c|
        c.with_column { "Content" }
      end
      assert_has_class(gap_class)
    end
  end

  def test_falls_back_to_gap_3_for_invalid_gap
    render_inline(Bali::Columns::Component.new(gap: :invalid)) do |c|
      c.with_column { "Content" }
    end
    assert_has_class("gap-3")
  end

  # === Modifiers ===

  def test_wrap_applies_flex_wrap
    render_inline(Bali::Columns::Component.new(wrap: true)) do |c|
      c.with_column { "Content" }
    end
    assert_has_class("flex-wrap")
  end

  def test_center_applies_justify_center
    render_inline(Bali::Columns::Component.new(center: true)) do |c|
      c.with_column(size: :half) { "Centered" }
    end
    assert_has_class("justify-center")
  end

  def test_middle_applies_items_center
    render_inline(Bali::Columns::Component.new(middle: true)) do |c|
      c.with_column { "Middle" }
    end
    assert_has_class("items-center")
  end

  def test_mobile_keeps_flex_row_without_stacking
    render_inline(Bali::Columns::Component.new(mobile: true)) do |c|
      c.with_column { "Content" }
    end
    assert_has_class("flex")
    html = page.native.inner_html
    refute_match(/flex-col/, html)
  end

  def test_default_stacks_on_mobile
    render_inline(@component) do |c|
      c.with_column { "Content" }
    end
    assert_has_class("flex-col")
    assert_has_class("md:flex-row")
  end

  # === Column numeric sizes ===

  (1..12).each do |size|
    expected = Bali::Columns::Column::Component::NUMERIC_WIDTHS[size]
    define_method("test_numeric_size_#{size}") do
      render_inline(Bali::Columns::Component.new) do |c|
        c.with_column(size: size) { "Column #{size}" }
      end
      assert_has_class("md:#{expected}")
    end
  end

  # === Column symbolic sizes ===

  {
    full: "w-full",
    half: "w-1/2",
    one_third: "w-1/3",
    third: "w-1/3",
    two_thirds: "w-2/3",
    one_quarter: "w-1/4",
    quarter: "w-1/4",
    three_quarters: "w-3/4",
    one_fifth: "w-1/5",
    two_fifths: "w-2/5",
    three_fifths: "w-3/5",
    four_fifths: "w-4/5"
  }.each do |size_name, tw_class|
    define_method("test_symbolic_size_#{size_name}") do
      render_inline(Bali::Columns::Component.new) do |c|
        c.with_column(size: size_name) { "#{size_name} column" }
      end
      assert_has_class("md:#{tw_class}")
    end
  end

  # === Auto width ===

  def test_auto_width_applies_w_auto_and_shrink_0
    render_inline(@component) do |c|
      c.with_column(auto: true) { "Auto" }
    end
    assert_has_class("md:w-auto")
    assert_has_class("shrink-0")
  end

  # === Custom classes passthrough ===

  def test_custom_classes_on_container
    render_inline(Bali::Columns::Component.new(class: "custom-container")) do |c|
      c.with_column { "Content" }
    end
    assert_has_class("custom-container")
    assert_has_class("flex")
  end

  def test_custom_classes_on_column
    render_inline(@component) do |c|
      c.with_column(class: "custom-column") { "Content" }
    end
    assert_has_class("custom-column")
  end

  def test_data_attributes_on_container
    render_inline(Bali::Columns::Component.new(data: { testid: "columns" })) do |c|
      c.with_column { "Content" }
    end
    assert_selector('[data-testid="columns"]')
  end

  def test_data_attributes_on_column
    render_inline(@component) do |c|
      c.with_column(data: { testid: "column" }) { "Content" }
    end
    assert_selector('[data-testid="column"]')
  end

  # === Responsive sizes (md/lg/xl breakpoints) ===

  def test_responsive_md_numeric_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(md: 6) { "md 6" }
    end
    assert_has_class("md:w-6/12")
  end

  def test_responsive_md_symbolic_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(md: :half) { "md half" }
    end
    assert_has_class("md:w-1/2")
  end

  def test_responsive_lg_numeric_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(lg: 4) { "lg 4" }
    end
    assert_has_class("lg:w-4/12")
  end

  def test_responsive_lg_symbolic_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(lg: :one_third) { "lg third" }
    end
    assert_has_class("lg:w-1/3")
  end

  def test_responsive_xl_numeric_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(xl: 3) { "xl 3" }
    end
    assert_has_class("xl:w-3/12")
  end

  def test_responsive_xl_symbolic_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(xl: :half) { "xl half" }
    end
    assert_has_class("xl:w-1/2")
  end

  def test_responsive_combined_base_and_lg
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(size: :half, lg: :one_quarter) { "Combined" }
    end
    assert_has_class("md:w-1/2")
    assert_has_class("lg:w-1/4")
  end

  def test_responsive_all_breakpoints
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(size: :full, md: :half, lg: :one_third, xl: :one_quarter) { "All" }
    end
    assert_has_class("md:w-full")
    assert_has_class("md:w-1/2")
    assert_has_class("lg:w-1/3")
    assert_has_class("xl:w-1/4")
  end

  def test_responsive_nil_values_add_no_breakpoint_classes
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(size: :half, md: nil, lg: nil, xl: nil) { "No responsive" }
    end
    html = page.native.inner_html
    assert_has_class("md:w-1/2")
    refute_match(/lg:/, html)
    refute_match(/xl:/, html)
  end

  def test_responsive_stat_cards_pattern
    render_inline(Bali::Columns::Component.new(mobile: true, gap: :lg)) do |c|
      4.times { c.with_column(md: :half, lg: :one_quarter) { "Stat" } }
    end
    assert_selector("[class*='md:w-1/2'][class*='lg:w-1/4']", count: 4)
  end

  def test_responsive_main_sidebar_pattern
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(lg: :two_thirds) { "Main" }
      c.with_column(lg: :one_third) { "Sidebar" }
    end
    assert_has_class("lg:w-2/3")
    assert_has_class("lg:w-1/3")
  end

  def test_responsive_with_numeric_mixed_breakpoints
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(md: 6, lg: 4, xl: 3) { "Shrinking" }
    end
    assert_has_class("md:w-6/12")
    assert_has_class("lg:w-4/12")
    assert_has_class("xl:w-3/12")
  end

  # === Grid auto-flow mode (cols:) ===

  def test_grid_mode_renders_grid_class
    render_inline(Bali::Columns::Component.new(cols: 2)) { "Content" }
    assert_has_class("grid")
    refute_has_class("flex")
  end

  def test_grid_mode_applies_grid_cols_class
    render_inline(Bali::Columns::Component.new(cols: 3)) { "Content" }
    assert_has_class("grid-cols-3")
  end

  def test_grid_mode_renders_content_directly
    render_inline(Bali::Columns::Component.new(cols: 2)) { "<p>Direct child</p>".html_safe }
    assert_selector("p", text: "Direct child")
  end

  def test_grid_mode_applies_gap
    render_inline(Bali::Columns::Component.new(cols: 2, gap: :xl)) { "Content" }
    assert_has_class("gap-6")
  end

  def test_grid_mode_with_md_breakpoint
    render_inline(Bali::Columns::Component.new(cols: 1, cols_md: 2)) { "Content" }
    assert_has_class("grid-cols-1")
    assert_has_class("md:grid-cols-2")
  end

  def test_grid_mode_with_lg_breakpoint
    render_inline(Bali::Columns::Component.new(cols: 1, cols_lg: 3)) { "Content" }
    assert_has_class("grid-cols-1")
    assert_has_class("lg:grid-cols-3")
  end

  def test_grid_mode_with_xl_breakpoint
    render_inline(Bali::Columns::Component.new(cols: 1, cols_xl: 4)) { "Content" }
    assert_has_class("grid-cols-1")
    assert_has_class("xl:grid-cols-4")
  end

  def test_grid_mode_all_breakpoints
    render_inline(Bali::Columns::Component.new(cols: 1, cols_md: 2, cols_lg: 3, cols_xl: 4)) { "Content" }
    assert_has_class("grid-cols-1")
    assert_has_class("md:grid-cols-2")
    assert_has_class("lg:grid-cols-3")
    assert_has_class("xl:grid-cols-4")
  end

  def test_grid_mode_with_custom_class
    render_inline(Bali::Columns::Component.new(cols: 2, class: "mt-6")) { "Content" }
    assert_has_class("mt-6")
    assert_has_class("grid")
  end

  def test_slots_override_grid_mode
    render_inline(Bali::Columns::Component.new(cols: 2)) do |c|
      c.with_column(size: :half) { "Slot content" }
    end
    assert_has_class("flex")
    refute_has_class("grid")
    assert_has_class("md:w-1/2")
  end

  def test_grid_mode_form_pattern
    render_inline(Bali::Columns::Component.new(cols: 1, cols_md: 2, gap: :lg)) {
      '<input type="text"><input type="text"><input type="text"><input type="text">'.html_safe
    }
    assert_has_class("grid-cols-1")
    assert_has_class("md:grid-cols-2")
    assert_has_class("gap-4")
    assert_selector("input", count: 4)
  end

  def test_grid_mode_stat_cards_pattern
    render_inline(Bali::Columns::Component.new(cols: 1, cols_md: 2, cols_lg: 4, gap: :lg)) {
      "<div>Stat</div><div>Stat</div><div>Stat</div><div>Stat</div>".html_safe
    }
    assert_has_class("grid-cols-1")
    assert_has_class("md:grid-cols-2")
    assert_has_class("lg:grid-cols-4")
    assert_has_class("gap-4")
  end

  # === Real-world layouts ===

  def test_two_half_columns
    render_inline(@component) do |c|
      c.with_column(size: :half) { "Left" }
      c.with_column(size: :half) { "Right" }
    end
    assert_selector("[class*='md:w-1/2']", count: 2)
  end

  def test_4_8_split
    render_inline(@component) do |c|
      c.with_column(size: 4) { "Sidebar" }
      c.with_column(size: 8) { "Main" }
    end
    assert_has_class("md:w-4/12")
    assert_has_class("md:w-8/12")
  end

  def test_three_equal_columns
    render_inline(@component) do |c|
      c.with_column(size: :one_third) { "One" }
      c.with_column(size: :one_third) { "Two" }
      c.with_column(size: :one_third) { "Three" }
    end
    assert_selector("[class*='md:w-1/3']", count: 3)
  end

  def test_centered_half_width_column
    render_inline(Bali::Columns::Component.new(center: true)) do |c|
      c.with_column(size: :half) { "Centered content" }
    end
    assert_has_class("justify-center")
    assert_has_class("md:w-1/2")
  end

  # === Unsized columns get flex-1 ===

  def test_unsized_column_gets_flex_1
    render_inline(@component) do |c|
      c.with_column { "Flexible" }
    end
    assert_has_class("md:flex-1")
    assert_has_class("min-w-0")
  end

  # === Mobile mode disables stacking prefix ===

  def test_mobile_mode_columns_have_no_md_prefix_on_flex_1
    render_inline(Bali::Columns::Component.new(mobile: true)) do |c|
      c.with_column { "No prefix" }
    end
    html = page.native.inner_html
    assert_match(/\bflex-1\b/, html)
    assert_has_class("min-w-0")
  end

  def test_mobile_mode_sized_columns_have_no_md_prefix
    render_inline(Bali::Columns::Component.new(mobile: true)) do |c|
      c.with_column(size: :half) { "No prefix" }
    end
    html = page.native.inner_html
    assert_match(/\bw-1\/2\b/, html)
    refute_match(/md:w-1\/2/, html)
  end
end
