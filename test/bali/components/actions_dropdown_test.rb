# frozen_string_literal: true

require "test_helper"

# Bali::ActionsDropdown is a preset of Bali::Dropdown now, so most of what this file used to
# assert is asserted once, in dropdown_test.rb. What is left is the preset itself — the
# trigger it chooses — plus the accessibility it did NOT have while it was a second
# implementation of the same menu, which is the whole reason the two were merged.
class BaliActionsDropdownComponentTest < ComponentTestCase
  def test_it_is_a_dropdown
    assert_operator(Bali::ActionsDropdown::Component, :<, Bali::Dropdown::Component)
  end

  def test_renders_the_dropdown_wrapper
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector("div.dropdown.dropdown-start")
    assert_selector("ul.dropdown-content.menu")
    assert_selector("ul.dropdown-content li a", text: "Edit")
  end

  def test_default_trigger_is_an_icon_button
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector(".btn.btn-ghost.btn-circle.btn-sm svg")
  end

  def test_default_trigger_takes_a_custom_icon
    render_inline(Bali::ActionsDropdown::Component.new(icon: "more")) do |c|
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector(".btn.btn-circle svg")
  end

  # The ⋯ is an icon with no text, so with no name a screen reader announces "button" and
  # stops there. The old trigger carried `aria-haspopup` and no label at all.
  def test_default_trigger_is_named
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-dropdown-target="trigger"][aria-label="Actions"]')
  end

  # Everything below was absent while this was its own component: no controller, so no arrow
  # keys and no Escape; no `role="menu"`; no `aria-expanded` emitted at all.
  def test_it_now_carries_the_dropdown_controller
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-controller="dropdown"]')
    assert_selector('[data-dropdown-target="trigger"][aria-haspopup="true"][aria-expanded="false"]')
    assert_selector('ul[role="menu"][aria-label="Dropdown menu"][data-dropdown-target="menu"]')
    assert_selector('a[role="menuitem"]')
  end

  def test_custom_trigger_replaces_the_preset_one
    render_inline(Bali::ActionsDropdown::Component.new) do |c|
      c.with_trigger(variant: :ghost) { "Actions" }
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-dropdown-target="trigger"]', text: "Actions")
    assert_no_selector(".btn-circle")
  end

  def test_custom_content_fallback_renders_block_content_when_no_items_provided
    render_inline(Bali::ActionsDropdown::Component.new) do
      '<li><a href="#">Custom Link</a></li>'.html_safe
    end
    assert_selector("ul.menu li a", text: "Custom Link")
  end

  def test_render_behavior_does_not_render_when_no_items_and_no_content
    result = render_inline(Bali::ActionsDropdown::Component.new)
    assert_empty(result.to_html)
  end

  # The old popover mode rendered something else entirely — a HoverCard whose menu was a
  # STRING copy of the list, outside the wrapper, with no roles and no controller. It is the
  # same markup as the CSS mode now, with one Stimulus value flipped.
  def test_popover_mode_is_the_same_markup_with_one_value_flipped
    render_inline(Bali::ActionsDropdown::Component.new(popover: true, align: :end)) do |c|
      c.with_item(name: "Edit", href: "#")
    end
    assert_selector('[data-dropdown-popover-value="true"]')
    assert_selector('[data-dropdown-placement-value="bottom-end"]')
    assert_selector('div.dropdown > ul[role="menu"].dropdown-content')
    assert_no_selector(".hover-card-component")
  end
end
