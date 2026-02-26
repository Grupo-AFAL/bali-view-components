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
