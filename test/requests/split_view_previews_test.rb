# frozen_string_literal: true

require "test_helper"

# The preview is the first documentation anyone copies, so what the default
# scenario teaches is what hosts will write. These pin the doctrine — structured
# listing as the face, free master as the escape — and the two silent failures
# this file was written after.
class SplitViewPreviewsTest < ActionDispatch::IntegrationTest
  BASE = "/lookbook/preview/bali/split_view"

  SCENARIOS = %w[
    default multi_filters with_selection deep_link_beyond_the_first_page
    without_advance custom_master full_height/default
  ].freeze

  def setup
    studio = Tenant.create!(name: "Preview Studio")
    studio.movies.create!(name: "Preview Movie", genre: "Drama", status: 0)
  end

  def test_every_scenario_renders
    SCENARIOS.each do |scenario|
      get "#{BASE}/#{scenario}"
      assert_response :ok, "#{scenario} no renderizó"
    end
  end

  # The face of the component is the structured listing: rows the component
  # wired, not markup a host copied.
  def test_the_default_scenario_teaches_the_structured_list
    get "#{BASE}/default"

    assert_select "a.split-view-item[data-split-view-target='row']", { minimum: 1 },
      "el default tiene que enseñar with_list/with_item, no un master a mano"
    assert_select "a.split-view-item[data-turbo-frame='split-view-detail']", minimum: 1
  end

  # And the escape hatch stays reachable, clearly marked as the other thing.
  def test_the_custom_master_scenario_keeps_the_hand_rolled_listing
    get "#{BASE}/custom_master"

    assert_select ".split-view-master .split-view-row", minimum: 1
    assert_select "a.split-view-item", false,
      "custom_master es el escape: sus filas se escriben a mano"
  end

  # The pills build their own URLs from the request, so a preview is a real
  # filter: the param narrows the listing and marks the pill.
  def test_the_filter_pills_are_live_in_single_mode
    get "#{BASE}/default"
    assert_select ".split-view-filter[data-active='true']", false, "sin filtro no hay pill activa"

    get "#{BASE}/default", params: { status: "done" }
    assert_select ".split-view-filter[data-active='true']", 1
    assert_select ".split-view-filter[aria-current='true']", 1
  end

  # Several active at once, and `aria-current` cannot say "all of these" — so it
  # is absent and the state lives in text.
  def test_multi_mode_marks_several_pills_without_aria_current
    get "#{BASE}/multi_filters", params: { q: { genre_in: %w[Action Comedy] } }

    assert_select ".split-view-filter[data-active='true']", { minimum: 2 }
    assert_select ".split-view-filter[aria-current]", false
    assert_select ".split-view-filter[aria-pressed]", false
  end

  # The one that would have caught the silent failure: `@layout` is not a tag
  # Lookbook 2.3 knows, so the annotation was ignored and AppLayout's <body> —
  # and with it `app-layout--viewport-locked` — was discarded by the parser. The
  # scenario still looked plausible while demonstrating nothing, because `:full`
  # filled a <main> that was not the screen.
  def test_the_full_height_scenario_really_locks_the_viewport
    get "#{BASE}/full_height/default"

    assert_select "body.app-layout--viewport-locked", 1,
      "sin la clase de lock, `height: :full` no tiene contra qué llenar"
    assert_select ".split-view-component--full", 1
  end
end
