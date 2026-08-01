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

  # `icon_name:` has to stay in the signature rather than be deleted: **options
  # becomes HTML attributes, so a missed call site would render
  # `icon_name="users"` on the card, with no icon and nothing to read.
  def test_icon_name_still_works_and_warns
    captured = []
    previous = Bali.deprecator.behavior
    Bali.deprecator.behavior = ->(message, *) { captured << message }

    render_inline(Bali::StatCard::Component.new(**default_attrs.except(:icon), icon_name: "users"))

    assert_includes(captured.join("\n"), "`icon_name:` is deprecated")
    assert_selector("svg")
  ensure
    Bali.deprecator.behavior = previous
  end

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
end
