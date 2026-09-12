# frozen_string_literal: true

require "test_helper"

# #1081: a keyword that names one of a component's own slots used to be swallowed by its
# `**options` and painted as an HTML attribute — valid HTML, no exception, and the content
# gone. `Bali::Card::Component.new(title: "Data")` left ten cards in one host app without
# their heading for months.
class BaliSlotKeywordGuardTest < ComponentTestCase
  def teardown
    Bali.raise_on_slot_keyword_conflict = nil
    super
  end

  def test_a_slot_name_passed_as_a_keyword_raises
    error = assert_raises(ArgumentError) do
      Bali::Card::Component.new(title: "Data governance")
    end

    assert_match "`title:`", error.message
    assert_match "Bali::Card::Component", error.message
    assert_match "with_title", error.message
  end

  # Not a Card quirk: every component that keeps a `**options` and declares slots had the
  # same hole. Hero is one of the several the guard covers for free.
  def test_the_guard_is_not_specific_to_card
    assert_raises(ArgumentError) { Bali::Hero::Component.new(title: "Welcome") }
  end

  def test_several_conflicting_keywords_are_named_at_once
    error = assert_raises(ArgumentError) do
      Bali::Card::Component.new(title: "Data", image: "/cover.png")
    end

    assert_match "`title:`", error.message
    assert_match "`image:`", error.message
  end

  # PageHeader declares BOTH: `title:` is its shorthand and `with_title` the full form.
  # The rule is not "the name is a slot" but "the keyword has nowhere else to go".
  def test_a_component_that_declares_the_keyword_keeps_taking_it
    render_inline(Bali::PageHeader::Component.new(title: "Studios"))

    assert_selector "h1", text: "Studios"
  end

  def test_options_that_name_no_slot_still_reach_the_element
    render_inline(Bali::Card::Component.new(id: "data-card", data: { role: "panel" }))

    assert_selector "#data-card.card[data-role='panel']"
  end

  # The deliberate tooltip stays reachable, and it has to be spelled differently from the
  # mistake or the guard would have nothing to go on.
  def test_a_string_key_is_the_way_to_ask_for_the_html_attribute
    render_inline(Bali::Card::Component.new("title" => "Tooltip")) { "Body" }

    assert_selector ".card[title='Tooltip']"
  end

  # Same posture as raise_on_missing_translations: a heading that has been missing since
  # the deploy should not become a 500 in production.
  def test_the_guard_is_a_pass_through_when_turned_off
    Bali.raise_on_slot_keyword_conflict = false

    render_inline(Bali::Card::Component.new(title: "Data governance")) { "Body" }

    assert_selector ".card[title='Data governance']"
  end

  def test_a_component_with_no_options_hash_is_left_to_ruby
    assert_empty Bali::LocationsMap::Location::Component.slot_keywords
  end

  def test_the_slot_still_renders_the_heading
    render_inline(Bali::Card::Component.new) { |card| card.with_title("Data governance") }

    assert_selector ".card-body h2.card-title", text: "Data governance"
    assert_no_selector ".card[title]"
  end
end
