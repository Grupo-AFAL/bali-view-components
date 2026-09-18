# frozen_string_literal: true

require "test_helper"

class BaliStatCardComponentTest < ComponentTestCase
  private

  def default_attrs
    { title: "Total Users", value: "1,234", icon: "users", color: :primary }
  end

  public

  def test_basic_rendering_renders_a_card_with_the_title
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    assert_text("Total Users")
  end

  def test_basic_rendering_renders_the_value
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    assert_text("1,234")
  end

  def test_basic_rendering_renders_the_icon
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    assert_selector("svg") # Lucide icon
  end

  def test_basic_rendering_renders_inside_a_card_component
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    assert_selector(".card")
  end
  Bali::StatCard::Component::COLORS.each_key do |color|
    define_method("test_colors_applies_#{color}_color_classes") do
      render_inline(Bali::StatCard::Component.new(**default_attrs, color: color))
      color_classes = Bali::StatCard::Component::COLORS[color]
      assert_selector(".#{color_classes[:bg].gsub('/', '\\/')}")
    end
  end

  def test_defaults_to_primary_color
    render_inline(Bali::StatCard::Component.new(**default_attrs.except(:color), color: nil))
    # Should fallback to primary
    assert_selector(".bg-primary\\/10")
  end

  def test_footer_slot_renders_the_footer_when_provided
    render_inline(Bali::StatCard::Component.new(**default_attrs)) do |card|
      card.with_footer { "Footer content" }
    end
    assert_text("Footer content")
  end

  def test_footer_slot_does_not_render_footer_container_when_not_provided
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    # Footer container should not exist without the slot
    assert_selector(".card")
    assert_no_selector(".mt-3.flex.items-center.gap-1.text-sm")
  end

  def test_private_attribute_readers_has_private_title_reader
    component = Bali::StatCard::Component.new(**default_attrs)
    assert_includes(component.private_methods, :title)
  end

  def test_private_attribute_readers_has_private_value_reader
    component = Bali::StatCard::Component.new(**default_attrs)
    assert_includes(component.private_methods, :value)
  end

  def test_private_attribute_readers_has_private_icon_reader
    component = Bali::StatCard::Component.new(**default_attrs)
    assert_includes(component.private_methods, :icon)
  end

  # The `icon_name:` shim lives in test/bali/deprecated_icon_name_test.rb, with the other six.

  def test_private_attribute_readers_has_private_color_reader
    component = Bali::StatCard::Component.new(**default_attrs)
    assert_includes(component.private_methods, :color)
  end

  def test_private_attribute_readers_has_private_options_reader
    component = Bali::StatCard::Component.new(**default_attrs)
    assert_includes(component.private_methods, :options)
  end

  def test_icon_background_classes_returns_correct_bg_class_for_primary
    component = Bali::StatCard::Component.new(**default_attrs, color: :primary)
    assert_equal("bg-primary/10", component.icon_bg_class)
  end

  def test_icon_background_classes_returns_correct_bg_class_for_warning
    component = Bali::StatCard::Component.new(**default_attrs, color: :warning)
    assert_equal("bg-warning/10", component.icon_bg_class)
  end

  def test_icon_background_classes_rejects_an_unknown_color
    error = assert_raises(ArgumentError) do
      Bali::StatCard::Component.new(**default_attrs, color: :unknown)
    end
    assert_includes(error.message, "unknown color :unknown")
  end

  def test_icon_text_classes_returns_correct_text_class_for_primary
    component = Bali::StatCard::Component.new(**default_attrs, color: :primary)
    assert_equal("text-primary", component.icon_text_class)
  end

  def test_icon_text_classes_returns_correct_text_class_for_success
    component = Bali::StatCard::Component.new(**default_attrs, color: :success)
    assert_equal("text-success", component.icon_text_class)
  end

  def test_icon_text_classes_ghost_takes_the_theme_surface
    component = Bali::StatCard::Component.new(**default_attrs, color: :ghost)
    assert_equal("bg-base-200", component.icon_bg_class)
    assert_equal("text-base-content", component.icon_text_class)
  end

  def test_icon_text_classes_custom_color_replaces_both_classes_with_inline_styles
    component = Bali::StatCard::Component.new(**default_attrs, custom_color: "#ff0000")
    assert_nil(component.icon_bg_class)
    assert_equal("color: #ff0000", component.icon_style)
    assert_includes(component.icon_container_style, "#ff0000")
  end

  def test_colors_constant_is_frozen
    assert(Bali::StatCard::Component::COLORS.frozen?)
  end

  def test_colors_constant_has_bg_and_text_keys_for_each_color
    Bali::StatCard::Component::COLORS.each_value do |classes|
      assert(classes.key?(:bg))
      assert(classes.key?(:text))
  end
  end

  def test_card_options_includes_bordered_style
      component = Bali::StatCard::Component.new(**default_attrs)
      assert_equal(:bordered, component.card_options[:style])
  end

  def test_card_options_passes_through_custom_options
      component = Bali::StatCard::Component.new(**default_attrs, class: "custom-class")
      assert_equal("custom-class", component.card_options[:class])
  end

  def test_card_options_passes_through_data_attributes
      component = Bali::StatCard::Component.new(**default_attrs, data: { testid: "stat" })
      assert_equal({ testid: "stat" }, component.card_options[:data])
  end

  def test_icon_container_classes_includes_base_classes
      component = Bali::StatCard::Component.new(**default_attrs)
      assert_includes(component.icon_container_classes, "p-3")
      assert_includes(component.icon_container_classes, "rounded-full")
  end

  def test_icon_container_classes_includes_color_specific_background_class
      component = Bali::StatCard::Component.new(**default_attrs, color: :warning)
      assert_includes(component.icon_container_classes, "bg-warning/10")
  end

  def test_numeric_values_handles_integer_values
      render_inline(Bali::StatCard::Component.new(**default_attrs, value: 42))
      assert_text("42")
  end

  def test_numeric_values_handles_formatted_currency_values
      render_inline(Bali::StatCard::Component.new(**default_attrs, value: "$1,234,567"))
      assert_text("$1,234,567")
  end

  def test_numeric_values_handles_percentage_values
      render_inline(Bali::StatCard::Component.new(**default_attrs, value: "78%"))
      assert_text("78%")
  end

  def test_href_renders_the_whole_card_as_a_link
    render_inline(Bali::StatCard::Component.new(**default_attrs, href: "/users"))
    assert_selector("a.card[href='/users']", text: "Total Users")
    assert_selector("a.card.transition-shadow.hover\\:shadow-md")
    assert_no_selector("div.card")
  end

  def test_without_href_the_card_stays_a_div
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    assert_selector("div.card")
    assert_no_selector("a.card")
  end

  # --- The card surface, asserted on the DOM ---------------------------------
  #
  # `test_card_options_passes_through_*` above assert on the options hash, not on
  # what comes out. A second surface that skips `card_options` would leave them
  # green while dropping the passthrough, so the same claim is made here against
  # the rendered node.

  def test_card_surface_passes_class_id_and_data_through_to_the_rendered_root
    render_inline(
      Bali::StatCard::Component.new(
        **default_attrs, class: "custom-class", id: "stat-1", data: { testid: "stat" }
      )
    )
    assert_selector("div.card.custom-class#stat-1[data-testid='stat']")
  end

  # --- surface: :cell --------------------------------------------------------

  def test_cell_surface_does_not_render_a_card
    render_inline(Bali::StatCard::Component.new(**default_attrs.except(:icon), surface: :cell))
    assert_no_selector(".card")
    assert_no_selector("[surface]") # and does not leak as an HTML attribute either
    assert_text("Total Users")
    assert_text("1,234")
  end

  def test_cell_surface_renders_a_bordered_box
    render_inline(Bali::StatCard::Component.new(**default_attrs.except(:icon), surface: :cell))
    assert_selector("div.rounded-box.border.border-base-300.p-4.bg-base-100")
  end

  def test_cell_surface_passes_class_id_and_data_through_to_the_rendered_root
    render_inline(
      Bali::StatCard::Component.new(
        **default_attrs.except(:icon), surface: :cell,
        class: "custom-class", id: "cell-1", data: { testid: "cell" }
      )
    )
    assert_selector("div.rounded-box.custom-class#cell-1[data-testid='cell']")
  end

  def test_cell_surface_with_href_renders_an_anchor_with_the_hover_affordance
    render_inline(
      Bali::StatCard::Component.new(**default_attrs.except(:icon), surface: :cell, href: "/x")
    )
    assert_selector("a.rounded-box[href='/x']", text: "Total Users")
    assert_selector("a.transition-shadow.hover\\:shadow-md")
    assert_no_selector(".card")
  end

  def test_cell_surface_rejects_an_icon
    error = assert_raises(ArgumentError) do
      Bali::StatCard::Component.new(**default_attrs, surface: :cell)
    end
    assert_includes(error.message, "surface: :cell")
    assert_includes(error.message, "icon")
  end

  def test_an_unknown_surface_is_rejected
    error = assert_raises(ArgumentError) do
      Bali::StatCard::Component.new(**default_attrs, surface: :panel)
    end
    assert_includes(error.message, ":panel")
  end

  # --- emphasis --------------------------------------------------------------

  def test_cell_surface_is_untinted_by_default
    render_inline(Bali::StatCard::Component.new(**default_attrs.except(:icon), surface: :cell))
    assert_no_selector(".bg-primary\\/10")
    assert_selector(".border-base-300")
  end

  def test_emphasis_paints_the_cell_with_the_colour_pair
    render_inline(
      Bali::StatCard::Component.new(
        **default_attrs.except(:icon), surface: :cell, emphasis: true, color: :primary
      )
    )
    assert_selector(".bg-primary\\/10.border-primary\\/30")
    assert_no_selector(".border-base-300")
  end

  def test_emphasis_paints_every_colour_in_the_table
    Bali::StatCard::Component::COLORS.each do |color, classes|
      render_inline(
        Bali::StatCard::Component.new(
          **default_attrs.except(:icon), surface: :cell, emphasis: true, color: color
        )
      )
      assert_selector(".#{classes[:bg].gsub('/', '\\\\/')}.#{classes[:border].gsub('/', '\\\\/')}")
    end
  end

  def test_emphasis_with_a_custom_colour_paints_inline_instead_of_silently_doing_nothing
    render_inline(
      Bali::StatCard::Component.new(
        **default_attrs.except(:icon), surface: :cell, emphasis: true, custom_color: "#7c3aed"
      )
    )
    assert_selector("div[style*='background-color: color-mix']")
    assert_selector("div[style*='border-color: color-mix']")
  end

  def test_emphasis_is_rejected_on_the_card_surface
    error = assert_raises(ArgumentError) do
      Bali::StatCard::Component.new(**default_attrs, emphasis: true)
    end
    assert_includes(error.message, "emphasis:")
    assert_includes(error.message, "surface: :cell")
  end

  def test_colors_constant_has_a_border_class_for_each_color
    Bali::StatCard::Component::COLORS.each_value do |classes|
      assert(classes.key?(:border))
    end
  end

  # --- note: and value_class: ------------------------------------------------

  def test_note_renders_a_muted_third_line_on_the_cell_surface
    render_inline(
      Bali::StatCard::Component.new(
        **default_attrs.except(:icon), surface: :cell, note: "Crea valor \u00b7 tasa 12.5%"
      )
    )
    assert_selector("p.text-xs.text-base-content\\/60", text: "Crea valor \u00b7 tasa 12.5%")
  end

  def test_note_also_works_on_the_card_surface
    render_inline(Bali::StatCard::Component.new(**default_attrs, note: "Last 30 days"))
    assert_selector(".card p.text-xs", text: "Last 30 days")
  end

  def test_without_a_note_no_extra_paragraph_is_emitted
    render_inline(Bali::StatCard::Component.new(**default_attrs))
    assert_selector("p", count: 2) # title + value, exactly as before
  end

  def test_value_class_is_appended_to_the_value_paragraph
    render_inline(Bali::StatCard::Component.new(**default_attrs, value_class: "font-mono"))
    assert_selector("p.text-3xl.font-bold.font-mono", text: "1,234")
  end
end
