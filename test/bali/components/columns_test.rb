# frozen_string_literal: true

require "test_helper"

class BaliColumnsComponentTest < ComponentTestCase
  def setup
    @component = Bali::Columns::Component.new
  end

  def test_basic_rendering_renders_container_with_columns_class
    render_inline(@component) do |c|
      c.with_column { "First" }
      c.with_column { "Second" }
    end
    assert_selector("div.columns")
  end

  def test_basic_rendering_renders_columns_with_column_class
    render_inline(@component) do |c|
      c.with_column { "First" }
      c.with_column { "Second" }
    end
    assert_selector("div.column", count: 2)
  end

  def test_gap_sizes_tailwind_like_applies_default_gap_md_class
    render_inline(@component) do |c|
      c.with_column { "Content" }
    end
    assert_selector("div.columns.gap-md")
  end

  Bali::Columns::Component::GAPS.each do |gap_name, gap_class|
    define_method("test_gap_sizes_tailwind_like_applies_#{gap_class}_for_gap_#{gap_name}") do
      render_inline(Bali::Columns::Component.new(gap: gap_name)) do |c|
        c.with_column { "Content" }
      end
      assert_selector("div.columns.#{gap_class}")
    end
  end

  def test_falls_back_to_gap_md_for_invalid_gap
    render_inline(Bali::Columns::Component.new(gap: :invalid)) do |c|
      c.with_column { "Content" }
    end
    assert_selector("div.columns.gap-md")
  end

  def test_wrap_modifier_applies_columns_wrap_class_when_wrap_true
    render_inline(Bali::Columns::Component.new(wrap: true)) do |c|
      c.with_column { "Content" }
    end
    assert_selector("div.columns.columns-wrap")
  end

  def test_alignment_modifiers_applies_columns_center_when_center_true
    render_inline(Bali::Columns::Component.new(center: true)) do |c|
      c.with_column(size: :half) { "Centered" }
    end
    assert_selector("div.columns.columns-center")
  end

  def test_alignment_modifiers_applies_columns_middle_when_middle_true
    render_inline(Bali::Columns::Component.new(middle: true)) do |c|
      c.with_column { "Middle" }
    end
    assert_selector("div.columns.columns-middle")
  end

  def test_mobile_modifier_applies_columns_mobile_when_mobile_true
    render_inline(Bali::Columns::Component.new(mobile: true)) do |c|
      c.with_column { "Content" }
    end
    assert_selector("div.columns.columns-mobile")
  end

  (1..12).each do |size|
    define_method("test_column_sizes_numeric_applies_col_#{size}_for_size_#{size}") do
      render_inline(Bali::Columns::Component.new) do |c|
        c.with_column(size: size) { "Column #{size}" }
      end
      assert_selector("div.column.col-#{size}")
    end
  end

  {
    full: "col-full",
    half: "col-half",
    one_third: "col-third",
    third: "col-third",
    two_thirds: "col-2-thirds",
    one_quarter: "col-quarter",
    quarter: "col-quarter",
    three_quarters: "col-3-quarters",
    one_fifth: "col-fifth",
    two_fifths: "col-2-fifths",
    three_fifths: "col-3-fifths",
    four_fifths: "col-4-fifths"
  }.each do |size_name, size_class|
    define_method("test_symbolic_sizes_fractions_applies_#{size_class}_for_size_#{size_name}") do
      render_inline(Bali::Columns::Component.new) do |c|
        c.with_column(size: size_name) { "#{size_name} column" }
      end
      assert_selector("div.column.#{size_class}")
    end
  end

  def test_auto_width_columns_applies_col_auto_class_when_auto_true
    render_inline(@component) do |c|
      c.with_column(auto: true) { "Auto" }
    end
    assert_selector("div.column.col-auto")
  end

  (1..11).each do |offset|
    define_method("test_column_offsets_numeric_applies_offset_#{offset}_for_offset_#{offset}") do
      render_inline(Bali::Columns::Component.new) do |c|
        c.with_column(size: 6, offset: offset) { "Offset #{offset}" }
      end
      assert_selector("div.column.offset-#{offset}")
    end
  end

  {
    half: "offset-half",
    one_third: "offset-third",
    third: "offset-third",
    two_thirds: "offset-2-thirds",
    one_quarter: "offset-quarter",
    quarter: "offset-quarter",
    three_quarters: "offset-3-quarters",
    one_fifth: "offset-fifth",
    two_fifths: "offset-2-fifths",
    three_fifths: "offset-3-fifths",
    four_fifths: "offset-4-fifths"
  }.each do |offset_name, offset_class|
    define_method("test_symbolic_offsets_applies_#{offset_class}_for_offset_#{offset_name}") do
      render_inline(Bali::Columns::Component.new) do |c|
        c.with_column(size: :one_quarter, offset: offset_name) { "Offset #{offset_name}" }
      end
      assert_selector("div.column.#{offset_class}")
    end
  end

  def test_custom_classes_passthrough_accepts_custom_classes_on_container
    render_inline(Bali::Columns::Component.new(class: "custom-container")) do |c|
      c.with_column { "Content" }
    end
    assert_selector("div.columns.custom-container")
  end

  def test_custom_classes_passthrough_accepts_custom_classes_on_column
    render_inline(@component) do |c|
      c.with_column(class: "custom-column") { "Content" }
    end
    assert_selector("div.column.custom-column")
  end

  def test_custom_classes_passthrough_accepts_data_attributes_on_container
    render_inline(Bali::Columns::Component.new(data: { testid: "columns" })) do |c|
      c.with_column { "Content" }
    end
    assert_selector('div.columns[data-testid="columns"]')
  end

  def test_custom_classes_passthrough_accepts_data_attributes_on_column
    render_inline(@component) do |c|
      c.with_column(data: { testid: "column" }) { "Content" }
    end
    assert_selector('div.column[data-testid="column"]')
  end

  # === Responsive sizes ===

  def test_responsive_tablet_numeric_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(tablet: 6) { "Tablet 6" }
    end
    assert_selector("div.column.col-6-tablet")
  end

  def test_responsive_tablet_symbolic_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(tablet: :half) { "Tablet half" }
    end
    assert_selector("div.column.col-half-tablet")
  end

  def test_responsive_desktop_numeric_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(desktop: 4) { "Desktop 4" }
    end
    assert_selector("div.column.col-4-desktop")
  end

  def test_responsive_desktop_symbolic_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(desktop: :one_third) { "Desktop third" }
    end
    assert_selector("div.column.col-third-desktop")
  end

  def test_responsive_widescreen_numeric_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(widescreen: 3) { "Widescreen 3" }
    end
    assert_selector("div.column.col-3-widescreen")
  end

  def test_responsive_widescreen_symbolic_size
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(widescreen: :half) { "Widescreen half" }
    end
    assert_selector("div.column.col-half-widescreen")
  end

  def test_responsive_combined_base_and_desktop
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(size: :half, desktop: :one_quarter) { "Combined" }
    end
    assert_selector("div.column.col-half.col-quarter-desktop")
  end

  def test_responsive_all_breakpoints_together
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(size: :full, tablet: :half, desktop: :one_third, widescreen: :one_quarter) { "All" }
    end
    assert_selector("div.column.col-full.col-half-tablet.col-third-desktop.col-quarter-widescreen")
  end

  def test_responsive_nil_values_add_no_classes
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(size: :half, tablet: nil, desktop: nil, widescreen: nil) { "No responsive" }
    end
    html = page.native.inner_html
    assert_selector("div.column.col-half")
    refute_match(/tablet/, html)
    refute_match(/desktop/, html)
    refute_match(/widescreen/, html)
  end

  def test_responsive_stat_cards_pattern
    render_inline(Bali::Columns::Component.new(mobile: true, gap: :lg)) do |c|
      4.times { c.with_column(tablet: :half, desktop: :one_quarter) { "Stat" } }
    end
    assert_selector("div.column.col-half-tablet.col-quarter-desktop", count: 4)
  end

  def test_responsive_main_sidebar_pattern
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(desktop: :two_thirds) { "Main" }
      c.with_column(desktop: :one_third) { "Sidebar" }
    end
    assert_selector("div.column.col-2-thirds-desktop")
    assert_selector("div.column.col-third-desktop")
  end

  def test_responsive_with_numeric_mixed_breakpoints
    render_inline(Bali::Columns::Component.new) do |c|
      c.with_column(tablet: 6, desktop: 4, widescreen: 3) { "Shrinking" }
    end
    assert_selector("div.column.col-6-tablet.col-4-desktop.col-3-widescreen")
  end

  # === Grid auto-flow mode (cols:) ===

  def test_grid_mode_renders_columns_grid_class
    render_inline(Bali::Columns::Component.new(cols: 2)) { "Content" }
    assert_selector("div.columns-grid")
    assert_no_selector("div.columns")
  end

  def test_grid_mode_applies_cols_class
    render_inline(Bali::Columns::Component.new(cols: 3)) { "Content" }
    assert_selector("div.columns-grid.cols-3")
  end

  def test_grid_mode_renders_content_directly
    render_inline(Bali::Columns::Component.new(cols: 2)) { "<p>Direct child</p>".html_safe }
    assert_selector("div.columns-grid > p", text: "Direct child")
    assert_no_selector("div.column")
  end

  def test_grid_mode_applies_gap
    render_inline(Bali::Columns::Component.new(cols: 2, gap: :xl)) { "Content" }
    assert_selector("div.columns-grid.gap-xl")
  end

  def test_grid_mode_with_tablet_breakpoint
    render_inline(Bali::Columns::Component.new(cols: 1, cols_tablet: 2)) { "Content" }
    assert_selector("div.columns-grid.cols-1.cols-2-tablet")
  end

  def test_grid_mode_with_desktop_breakpoint
    render_inline(Bali::Columns::Component.new(cols: 1, cols_desktop: 3)) { "Content" }
    assert_selector("div.columns-grid.cols-1.cols-3-desktop")
  end

  def test_grid_mode_with_widescreen_breakpoint
    render_inline(Bali::Columns::Component.new(cols: 1, cols_widescreen: 4)) { "Content" }
    assert_selector("div.columns-grid.cols-1.cols-4-widescreen")
  end

  def test_grid_mode_all_breakpoints
    render_inline(Bali::Columns::Component.new(cols: 1, cols_tablet: 2, cols_desktop: 3, cols_widescreen: 4)) { "Content" }
    assert_selector("div.columns-grid.cols-1.cols-2-tablet.cols-3-desktop.cols-4-widescreen")
  end

  def test_grid_mode_with_custom_class
    render_inline(Bali::Columns::Component.new(cols: 2, class: "mt-6")) { "Content" }
    assert_selector("div.columns-grid.mt-6")
  end

  def test_slots_override_grid_mode
    render_inline(Bali::Columns::Component.new(cols: 2)) do |c|
      c.with_column(size: :half) { "Slot content" }
    end
    assert_selector("div.columns")
    assert_no_selector("div.columns-grid")
    assert_selector("div.column.col-half")
  end

  def test_grid_mode_form_pattern
    render_inline(Bali::Columns::Component.new(cols: 1, cols_tablet: 2, gap: :lg)) {
      '<input type="text"><input type="text"><input type="text"><input type="text">'.html_safe
    }
    assert_selector("div.columns-grid.cols-1.cols-2-tablet.gap-lg")
    assert_selector("div.columns-grid > input", count: 4)
  end

  def test_grid_mode_stat_cards_pattern
    render_inline(Bali::Columns::Component.new(cols: 1, cols_tablet: 2, cols_desktop: 4, gap: :lg)) {
      "<div>Stat</div><div>Stat</div><div>Stat</div><div>Stat</div>".html_safe
    }
    assert_selector("div.columns-grid.cols-1.cols-2-tablet.cols-4-desktop.gap-lg")
  end

  # === Real-world layouts ===

  def test_real_world_layouts_renders_two_half_columns_correctly
    render_inline(@component) do |c|
      c.with_column(size: :half) { "Left" }
      c.with_column(size: :half) { "Right" }
    end
    assert_selector("div.column.col-half", count: 2)
  end

  def test_real_world_layouts_renders_4_8_split_with_col_4_and_col_8
    render_inline(@component) do |c|
      c.with_column(size: 4) { "Sidebar" }
      c.with_column(size: 8) { "Main" }
    end
    assert_selector("div.column.col-4")
    assert_selector("div.column.col-8")
  end

  def test_real_world_layouts_renders_three_equal_columns
    render_inline(@component) do |c|
      c.with_column(size: :one_third) { "One" }
      c.with_column(size: :one_third) { "Two" }
      c.with_column(size: :one_third) { "Three" }
    end
    assert_selector("div.column.col-third", count: 3)
  end

  def test_real_world_layouts_renders_centered_half_width_column
    render_inline(Bali::Columns::Component.new(center: true)) do |c|
      c.with_column(size: :half) { "Centered content" }
    end
    assert_selector("div.columns.columns-center")
    assert_selector("div.column.col-half")
  end
end
