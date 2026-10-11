# frozen_string_literal: true

require "test_helper"

class BaliLegendComponentTest < ComponentTestCase
  def test_renders_one_list_item_per_entry
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success)
      legend.with_item(label: "Draft", color: :ghost)
    end

    assert_selector("ul[role='list'] > li", count: 2)
    assert_selector("li", text: "Current")
    assert_selector("li", text: "Draft")
  end

  def test_the_list_is_labelled_by_the_title
    render_inline(Bali::Legend::Component.new(title: "States")) do |legend|
      legend.with_item(label: "Current", color: :success)
    end

    title_id = page.find("span", text: "States")[:id]
    assert_predicate(title_id, :present?)
    assert_selector("ul[role='list'][aria-labelledby='#{title_id}']")
    assert_no_selector("ul[aria-label]")
  end

  def test_without_a_title_the_list_takes_a_default_aria_label
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success)
    end

    assert_selector("ul[role='list'][aria-label='Legend']")
    assert_no_selector("ul[aria-labelledby]")
  end

  def test_aria_label_names_a_list_without_a_title
    render_inline(Bali::Legend::Component.new(aria_label: "Location types")) do |legend|
      legend.with_item(label: "Office", custom_color: "#7C3AED")
    end

    assert_selector("ul[role='list'][aria-label='Location types']")
  end

  def test_the_marker_is_hidden_from_assistive_tech
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success)
    end

    assert_selector(".legend-item__marker[aria-hidden='true']")
  end

  def test_a_named_dot_paints_the_theme_variable
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success)
    end

    assert_selector(".legend-item__marker--dot[style='background-color: var(--color-success)']")
  end

  def test_a_neutral_dot_paints_the_page_ink
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Obsolete", color: :neutral)
    end

    assert_selector(".legend-item__marker--dot[style='background-color: var(--color-base-content)']")
  end

  def test_custom_color_paints_the_hex_and_wins_over_color
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Commercial", color: :success, custom_color: "#2563EB")
    end

    assert_selector(".legend-item__marker--dot[style='background-color: #2563EB']")
  end

  def test_a_swatch_paints_a_tint_with_a_stronger_border
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "President", color: :primary, marker: :swatch)
    end

    style = "background-color: #{Bali::Color.with_alpha(:primary, 20)}; " \
            "border-color: #{Bali::Color.with_alpha(:primary, 40)}"
    assert_selector(".legend-item__marker--swatch[style='#{style}']")
    assert_no_selector(".legend-item__marker--dot")
  end

  def test_a_named_icon_takes_the_soft_ink
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success, icon: "circle-check")
    end

    assert_selector("li span.icon-component.text-soft-success[aria-hidden='true'] svg")
  end

  def test_a_hex_icon_takes_the_hex_mixed_into_the_ink
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Office", custom_color: "#7C3AED", icon: "building")
    end

    assert_selector("li span.icon-component[style='color: #{Bali::Color.soft('#7C3AED')}']")
  end

  def test_a_description_is_reachable_through_a_help_tip
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success, description: "Approved and in force")
    end

    assert_selector("li [data-controller='tooltip'] .trigger span.icon-component")
    assert_match(%r{<template data-tooltip-target="content">\s*Approved and in force\s*</template>},
                 rendered_content)
  end

  def test_a_blank_description_renders_no_help_tip
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success, description: "")
    end

    assert_no_selector("[data-controller='tooltip']")
  end

  def test_an_entry_without_a_colour_raises
    error = assert_raises(ArgumentError) do
      render_inline(Bali::Legend::Component.new) { |legend| legend.with_item(label: "Current") }
    end

    assert_match(/Bali::Legend::Item::Component.*color:.*custom_color:/, error.message)
  end

  def test_an_unknown_marker_raises_naming_the_valid_ones
    error = assert_raises(ArgumentError) do
      render_inline(Bali::Legend::Component.new) do |legend|
        legend.with_item(label: "Current", color: :success, marker: :square)
      end
    end

    assert_match(/marker :square.*:dot, :swatch/, error.message)
  end

  def test_options_pass_through_to_the_root
    render_inline(Bali::Legend::Component.new(id: "states", class: "mt-2", data: { testid: "legend" })) do |legend|
      legend.with_item(label: "Current", color: :success)
    end

    assert_selector("#states.legend-component.mt-2[data-testid='legend'] > ul")
  end

  def test_item_options_pass_through_to_the_list_item
    render_inline(Bali::Legend::Component.new) do |legend|
      legend.with_item(label: "Current", color: :success, class: "font-bold", data: { state: "current" })
    end

    assert_selector("li.legend-item.font-bold[data-state='current']")
  end
end
