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
    grouped_list without_advance frame_options custom_master full_height/default
  ].freeze

  def setup
    studio = Tenant.create!(name: "Preview Studio")
    studio.movies.create!(name: "Preview Movie", genre: "Drama", status: 0)
  end

  def test_every_scenario_renders
    SCENARIOS.each do |scenario|
      get "#{BASE}/#{scenario}"
      assert_response :ok, "#{scenario} did not render"
    end
  end

  # The face of the component is the structured listing: rows the component
  # wired, not markup a host copied.
  def test_the_default_scenario_teaches_the_structured_list
    get "#{BASE}/default"

    assert_select "a.split-view-item[data-split-view-target='row']", { minimum: 1 },
      "default has to teach with_list/with_item, not a hand-written master"
    assert_select "a.split-view-item[data-turbo-frame='split-view-detail']", minimum: 1
  end

  # And the escape hatch stays reachable, clearly marked as the other thing.
  def test_the_custom_master_scenario_keeps_the_hand_rolled_listing
    get "#{BASE}/custom_master"

    assert_select ".split-view-master .split-view-row", minimum: 1
    assert_select "a.split-view-item", false,
      "custom_master is the escape hatch: its rows are written by hand"
  end

  # The pills build their own URLs from the request, so a preview is a real
  # filter: the param narrows the listing and marks the pill.
  def test_the_filter_pills_are_live_in_single_mode
    get "#{BASE}/default"
    assert_select ".split-view-filter[data-active='true']", false, "no filter, no active pill"

    get "#{BASE}/default", params: { status: "done" }
    assert_select ".split-view-filter[data-active='true']", 1
    assert_select ".split-view-filter[aria-current='true']", 1
  end

  # Lookbook passes a preview method only the params it declares, so the status a
  # pill writes has to reach the listing some other way, in every scenario that
  # shows the pills — page one and the page the sentinel asks for next.
  def test_every_status_pill_filters_the_listing_it_lights
    studio = Tenant.find_by!(name: "Preview Studio")
    6.times { |i| studio.movies.create!(name: "Z Done Movie #{i}", genre: "Drama", status: :done) }

    %w[default with_selection deep_link_beyond_the_first_page grouped_list without_advance].each do |scenario|
      get "#{BASE}/#{scenario}", params: { status: "done" }

      assert_select ".split-view-filter[data-active='true']", { count: 1, text: /Done/ }, scenario
      assert_select ".split-view-item", { count: 5 }, scenario
      assert_select ".split-view-item", { count: 0, text: /Preview Movie/ }, "#{scenario} listed a draft"
      assert_select "[data-split-view-list-next-url-value*='status=done']", { count: 1 }, scenario
    end
  end

  # `q` arrives raw from the URL (#1210): typed as a scalar or a list it is not a hash, and
  # both the template and the pills read it as one.
  def test_every_scenario_survives_a_q_that_is_not_a_hash
    [ "x", [ "x" ] ].each do |q|
      SCENARIOS.each do |scenario|
        get "#{BASE}/#{scenario}", params: { q: q }
        assert_response :ok, "#{scenario} with q=#{q.inspect}"
      end
    end
  end

  # The dummy page is the full flow the guide sends hosts to copy, and its controller read
  # `q` the same way.
  def test_the_dummy_page_survives_a_q_that_is_not_a_hash
    [ "x", [ "x" ] ].each do |q|
      get "/split-view", params: { filter_mode: "multi", q: q }
      assert_response :ok, "/split-view with q=#{q.inspect}"
      assert_select ".split-view-filter[data-active='true']", false
    end
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
      "without the lock class, `height: :full` has nothing to fill"
    assert_select ".split-view-component--full", 1
  end
end
