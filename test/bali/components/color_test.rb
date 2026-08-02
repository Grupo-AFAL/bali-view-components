# frozen_string_literal: true

require "test_helper"

# The point of #691 is that `color:` means one thing across the library, so this
# file walks the seven components that take one rather than asserting the same
# thing seven times in seven files. A component added to COMPONENTS gets the
# whole contract for free; one that cannot pass it does not belong in the table.
class BaliColorContractTest < ComponentTestCase
  HEATMAP_DATA = { Mon: { 0 => 1, 1 => 2 }, Tue: { 0 => 3, 1 => 4 } }.freeze

  # Each entry takes the colour keywords and returns something render_inline can
  # take. Status is the odd one: its colour lives on an option rather than on the
  # component, which is exactly the kind of divergence the shared utility hides.
  COMPONENTS = {
    "Bali::Tag" => ->(**color) { Bali::Tag::Component.new(text: "Tag", **color) },
    "Bali::Status" => lambda { |**color|
      Bali::Status::Component.new(
        selected: "x", options: [ { value: "x", label: "X", **color } ]
      )
    },
    "Bali::Heatmap" => ->(**color) { Bali::Heatmap::Component.new(data: HEATMAP_DATA, **color) },
    "Bali::Chart" => ->(**color) { Bali::Chart::Component.new(data: { chocolate: 3 }, **color) },
    "Bali::Timeline::Item" => lambda { |**color|
      Bali::Timeline::Item::Component.new(heading: "Event", **color)
    },
    "Bali::StatCard" => lambda { |**color|
      Bali::StatCard::Component.new(title: "Users", value: "12", icon: "users", **color)
    },
    "Bali::Kanban::Column" => lambda { |**color|
      Bali::Kanban::Column::Component.new(title: "Todo", status: "todo", **color)
    }
  }.freeze

  COMPONENTS.each do |name, build|
    define_method("test_#{name.parameterize(separator: '_')}_accepts_every_semantic_name") do
      Bali::Color::NAMES.each do |color|
        render_inline(build.call(color: color))
        assert_selector("*", minimum: 1, visible: :all)
      end
    end

    define_method("test_#{name.parameterize(separator: '_')}_accepts_a_hex_custom_color") do
      render_inline(build.call(custom_color: "#ff8800"))
      assert_includes(rendered_content, "#ff8800")
    end

    define_method("test_#{name.parameterize(separator: '_')}_rejects_an_unknown_color") do
      error = assert_raises(ArgumentError) { render_inline(build.call(color: :chartreuse)) }
      assert_includes(error.message, "unknown color :chartreuse")
      assert_includes(error.message, name)
    end

    define_method("test_#{name.parameterize(separator: '_')}_rejects_a_bulma_color_by_name") do
      error = assert_raises(ArgumentError) { render_inline(build.call(color: :danger)) }
      assert_includes(error.message, "color: :error")
    end

    define_method("test_#{name.parameterize(separator: '_')}_rejects_a_non_hex_custom_color") do
      error = assert_raises(ArgumentError) { render_inline(build.call(custom_color: "red")) }
      assert_includes(error.message, "not a hex colour")
    end
  end
end

class BaliColorTest < ComponentTestCase
  def test_names_is_the_daisyui_semantic_palette_plus_ghost
    assert_equal(
      %i[neutral primary secondary accent info success warning error ghost],
      Bali::Color::NAMES
    )
  end

  def test_css_resolves_a_name_to_a_theme_variable
    assert_equal("var(--color-success)", Bali::Color.css(:success))
  end

  # There is no --color-ghost, so a component asking for a colour *value* gets
  # the theme's own foreground rather than an undefined variable.
  def test_css_resolves_ghost_to_base_content
    assert_equal("var(--color-base-content)", Bali::Color.css(:ghost))
  end

  def test_css_leaves_a_hex_alone
    assert_equal("#ff0000", Bali::Color.css("#ff0000"))
  end

  # Passing an already-resolved value back through must not double-wrap it, which
  # is how `var(--color-var(--color-primary))` would reach a stylesheet.
  def test_css_is_idempotent_on_a_value_it_produced
    assert_equal("var(--color-primary)", Bali::Color.css(Bali::Color.css(:primary)))
  end

  # DaisyUI 5 keeps a whole `oklch(...)` in the variable, so `oklch(var(--x) / .5)`
  # — the form this repo used to emit — is not valid CSS at all.
  def test_with_alpha_uses_color_mix_rather_than_an_alpha_channel
    assert_equal(
      "color-mix(in oklch, var(--color-primary) 40%, transparent)",
      Bali::Color.with_alpha(:primary, 40)
    )
  end

  def test_gradient_ramps_from_transparent_to_the_colour
    ramp = Bali::Color.gradient(:primary)
    assert_equal(10, ramp.size)
    assert_includes(ramp.first, "0%")
    assert_includes(ramp.last, "90%")
  end

  def test_cycle_from_rotates_so_the_named_colour_leads
    assert_equal(:success, Bali::Color.cycle_from(:success).first)
    assert_equal(Bali::Color::CYCLE.size, Bali::Color.cycle_from(:success).size)
  end

  # :neutral and :ghost are nameable but not part of the cycle, so they lead it
  # instead of being silently dropped.
  def test_cycle_from_prepends_a_colour_outside_the_cycle
    assert_equal(:neutral, Bali::Color.cycle_from(:neutral).first)
    assert_equal(Bali::Color::CYCLE.size + 1, Bali::Color.cycle_from(:neutral).size)
  end

  def test_hex_recognises_the_four_css_hex_forms
    %w[#fff #ffff #ffffff #ffffffff].each { |hex| assert(Bali::Color.hex?(hex), hex) }
    [ "fff", "#ff", "#fffff", "red", :red, nil ].each do |value|
      refute(Bali::Color.hex?(value), value.inspect)
    end
  end
end
