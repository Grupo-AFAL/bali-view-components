# frozen_string_literal: true

require "test_helper"

class BaliBarListComponentTest < ComponentTestCase
  ITEMS = [
    { label: "GERENTE DE RESTAURANTE CARL'S", value: 12, href: "/job_profiles/1" },
    { label: "COCINERO", value: 3 }
  ].freeze

  def test_renders_a_named_list_with_one_item_per_row
    render_inline(Bali::BarList::Component.new(items: ITEMS, aria_label: "People by job profile"))

    assert_selector("ul.bar-list[role='list'][aria-label='People by job profile'] > li", count: 2)
  end

  def test_the_label_is_written_in_full
    render_inline(Bali::BarList::Component.new(items: ITEMS))

    assert_selector(".bar-list__label", exact_text: "GERENTE DE RESTAURANTE CARL'S")
  end

  def test_a_row_with_href_is_one_link_named_by_its_label_and_figure
    render_inline(Bali::BarList::Component.new(items: ITEMS))

    assert_selector("li:first-child > a[href='/job_profiles/1']", exact_text: "GERENTE DE RESTAURANTE CARL'S 12",
                                                                   normalize_ws: true)
  end

  def test_a_row_without_href_is_not_a_link
    render_inline(Bali::BarList::Component.new(items: ITEMS))

    assert_no_selector("li:last-child a")
    assert_selector("li:last-child", text: "COCINERO")
  end

  def test_the_track_is_hidden_from_assistive_tech
    render_inline(Bali::BarList::Component.new(items: ITEMS))

    assert_selector("progress", count: 2)
    assert_selector("[aria-hidden='true'] > progress", count: 2)
  end

  def test_each_track_is_measured_against_the_largest_value
    render_inline(Bali::BarList::Component.new(items: ITEMS))

    assert_equal [ %w[12 12], %w[3 12] ], page.all("progress").map { |bar| [ bar[:value], bar[:max] ] }
  end

  def test_the_figure_takes_a_thousands_comma_and_a_decimal_point_under_es
    items = [ { label: "Tijuana", value: 13_887 }, { label: "Mexicali", value: 13_887.5 } ]

    I18n.with_locale(:es) { render_inline(Bali::BarList::Component.new(items: items)) }

    assert_equal %w[13,887 13,887.5], page.all(".bar-list__value").map(&:text)
  end

  def test_format_writes_the_figure
    render_inline(Bali::BarList::Component.new(items: ITEMS, format: ->(value) { "#{value} people" }))

    assert_equal [ "12 people", "3 people" ], page.all(".bar-list__value").map(&:text)
  end

  def test_the_bars_are_primary_by_default
    render_inline(Bali::BarList::Component.new(items: ITEMS))

    assert_selector("progress.progress-primary", count: 2)
  end

  def test_an_item_color_overrides_the_lists
    items = [ { label: "Open", value: 4, color: :error }, { label: "Closed", value: 9 } ]
    render_inline(Bali::BarList::Component.new(items: items, color: :success))

    assert_equal [ true, false ], page.all("progress").map { |bar| bar[:class].include?("progress-error") }
    assert_selector("progress.progress-success", count: 1)
  end

  def test_an_unknown_color_raises
    error = assert_raises(ArgumentError) { Bali::BarList::Component.new(items: ITEMS, color: :chartreuse) }
    assert_includes(error.message, "unknown color :chartreuse")
  end

  def test_an_unknown_item_color_raises_naming_the_bulma_replacement
    error = assert_raises(ArgumentError) do
      Bali::BarList::Component.new(items: [ { label: "Open", value: 1, color: :danger } ])
    end
    assert_includes(error.message, "color: :error")
  end

  def test_a_value_that_is_not_a_number_raises
    error = assert_raises(ArgumentError) do
      Bali::BarList::Component.new(items: [ { label: "Open", value: "12" } ])
    end
    assert_includes(error.message, %("12", not a number))
  end

  def test_an_item_id_lands_on_its_row
    render_inline(Bali::BarList::Component.new(items: [ { label: "Tijuana", value: 1, id: "district_7" } ]))

    assert_selector("li#district_7", text: "Tijuana")
  end

  # gobierno-corporativo's rows today carry `count:`, `link:` and `dom_id:`; handed over as they are,
  # an open set of keys would have painted `<li link="…">` and dropped the link without a word.
  def test_an_unknown_item_key_raises
    error = assert_raises(ArgumentError) do
      Bali::BarList::Component.new(items: [ { label: "Tijuana", value: 1, link: "<a href='/d/7'>Tijuana</a>" } ])
    end
    assert_includes(error.message, "unknown keyword: :link")
  end

  def test_host_options_land_on_the_list
    render_inline(Bali::BarList::Component.new(items: ITEMS, id: "staff", class: "mt-4"))

    assert_selector("ul#staff.bar-list.mt-4")
  end

  def test_renders_nothing_without_items
    render_inline(Bali::BarList::Component.new(items: []))

    assert_no_selector("ul")
  end
end
