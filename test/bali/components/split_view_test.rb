# frozen_string_literal: true

require "test_helper"

class BaliSplitViewComponentTest < ComponentTestCase
  def test_renders_master_and_detail_in_the_grid
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
      split.with_detail { "DETAIL" }
    end

    assert_selector("div.split-view-component .split-view-master", text: "MASTER")
    assert_selector("div.split-view-component turbo-frame.split-view-detail", text: "DETAIL", visible: :all)
  end

  def test_frame_carries_the_given_id
    render_inline(Bali::SplitView::Component.new(frame_id: "orders-detail")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector("turbo-frame#orders-detail", visible: :all)
  end

  def test_master_hosts_the_split_view_controller
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('.split-view-master[data-controller="split-view"]')
  end

  def test_advance_is_on_by_default
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('turbo-frame[data-turbo-action="advance"]', visible: :all)
  end

  def test_advance_false_omits_the_turbo_action
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", advance: false)) do |split|
      split.with_master { "MASTER" }
    end

    assert_no_selector("turbo-frame[data-turbo-action]", visible: :all)
  end

  def test_empty_detail_fills_the_frame_when_there_is_no_detail
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
      split.with_empty_detail { "NOTHING SELECTED" }
    end

    assert_selector("turbo-frame.split-view-detail", text: "NOTHING SELECTED", visible: :all)
  end

  def test_detail_wins_over_empty_detail
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
      split.with_detail { "DETAIL" }
      split.with_empty_detail { "NOTHING SELECTED" }
    end

    assert_selector("turbo-frame.split-view-detail", text: "DETAIL", visible: :all)
    assert_no_selector("turbo-frame.split-view-detail", text: "NOTHING SELECTED", visible: :all)
  end

  def test_default_master_width_reaches_the_custom_property
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('.split-view-component[style*="--bali-split-master-width: 420px"]')
  end

  def test_custom_master_width_reaches_the_custom_property
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", master_width: "24rem")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('.split-view-component[style*="--bali-split-master-width: 24rem"]')
  end

  def test_percentage_master_width_is_accepted
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", master_width: "35%")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('.split-view-component[style*="--bali-split-master-width: 35%"]')
  end

  # The value lands in a style attribute, so anything that is not a plain CSS
  # length has to be refused rather than interpolated.
  def test_master_width_that_is_not_a_css_length_raises
    error = assert_raises(ArgumentError) do
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", master_width: "420px; background: red"))
    end

    assert_match(/master_width must be a CSS length/, error.message)
  end

  def test_host_class_is_merged_and_host_style_is_kept
    render_inline(
      Bali::SplitView::Component.new(frame_id: "inbox-detail", class: "gap-6", style: "--bali-split-master-max-h: 30rem")
    ) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector(".split-view-component.gap-6")
    assert_selector('.split-view-component[style*="--bali-split-master-max-h: 30rem"]')
    assert_selector('.split-view-component[style*="--bali-split-master-width: 420px"]')
  end

  def test_arbitrary_html_options_reach_the_container
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", id: "inbox-split")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector("div#inbox-split.split-view-component")
  end
end
