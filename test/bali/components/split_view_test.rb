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

    assert_match(/master_width must be :equal or a CSS length/, error.message)
  end

  # --- height ---------------------------------------------------------------------------

  def test_height_content_is_the_default_and_adds_no_modifier
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector(".split-view-component")
    assert_no_selector(".split-view-component--full")
  end

  def test_height_full_adds_the_modifier
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", height: :full)) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector(".split-view-component.split-view-component--full")
  end

  # The modifier is the whole of `:full` — there is no inline height, no
  # `calc()` and no measured offset anywhere, which is what lets it fill a
  # bounded parent and honestly fill nothing without one.
  def test_height_full_adds_no_inline_height
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", height: :full)) do |split|
      split.with_master { "MASTER" }
    end

    refute_match(/height/, page.find(".split-view-component")["style"])
  end

  # Raises rather than falling back, like `master_width:`. A typo in the option
  # that IS this feature would otherwise render the default in silence, and the
  # symptom — a split that does not fill — sends the reader hunting in the CSS.
  def test_an_unknown_height_raises
    error = assert_raises(ArgumentError) do
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", height: :tall)) do |split|
        split.with_master { "MASTER" }
      end
    end

    assert_match(/height must be one of/, error.message)
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

  # --- frame_options --------------------------------------------------------------------

  def test_frame_options_reach_the_frame
    render_inline(
      Bali::SplitView::Component.new(frame_id: "inbox-detail",
                                     frame_options: { autoscroll: true, aria: { label: "Detail" } })
    ) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('turbo-frame#inbox-detail[autoscroll][aria-label="Detail"]', visible: :all)
  end

  def test_frame_options_data_is_merged_with_the_turbo_action_advance_writes
    render_inline(
      Bali::SplitView::Component.new(frame_id: "inbox-detail", frame_options: { data: { autoscroll_block: "start" } })
    ) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('turbo-frame[data-turbo-action="advance"][data-autoscroll-block="start"]', visible: :all)
  end

  def test_frame_options_data_reaches_the_frame_without_advance
    render_inline(
      Bali::SplitView::Component.new(frame_id: "inbox-detail", advance: false,
                                     frame_options: { data: { autoscroll_block: "start" } })
    ) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector('turbo-frame[data-autoscroll-block="start"]', visible: :all)
    assert_no_selector("turbo-frame[data-turbo-action]", visible: :all)
  end

  # Read off the markup, not a parsed frame: an attribute written twice parses
  # as its first copy, and an unnormalized string `"data"` key writes the host's
  # copy first — so the duplicate would parse as the right answer.
  def test_a_turbo_action_in_frame_options_replaces_advance_however_it_is_spelled
    [
      { data: { turbo_action: "replace" } },
      { data: { "turbo_action" => "replace" } },
      { data: { "turbo-action": "replace" } },
      { "data" => { "turbo-action" => "replace" } }
    ].each do |frame_options|
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", frame_options: frame_options)) do |split|
        split.with_master { "MASTER" }
      end

      assert_equal [ "replace" ], frame_tag_values("data-turbo-action"), frame_options.inspect
    end
  end

  def test_frame_options_class_is_added_to_the_frame_class
    [ { class: "scroll-mt-20" }, { "class" => "scroll-mt-20" } ].each do |frame_options|
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", frame_options: frame_options)) do |split|
        split.with_master { "MASTER" }
      end

      assert_equal [ "split-view-detail scroll-mt-20" ], frame_tag_values("class"), frame_options.inspect
    end
  end

  def test_frame_options_nil_or_data_nil_renders_the_default_frame
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
    end
    default_frame = page.find("turbo-frame").native.to_h

    [ nil, { data: nil } ].each do |frame_options|
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", frame_options: frame_options)) do |split|
        split.with_master { "MASTER" }
      end

      assert_equal default_frame, page.find("turbo-frame").native.to_h, frame_options.inspect
    end
  end

  # The rows, the list and the controller all find the frame by `frame_id:`, so it
  # wins the merge, and without the raise an `id:` here would vanish in silence.
  def test_frame_options_cannot_set_the_frame_id
    [ { id: "other" }, { "id" => "other" } ].each do |frame_options|
      error = assert_raises(ArgumentError, frame_options.inspect) do
        Bali::SplitView::Component.new(frame_id: "inbox-detail", frame_options: frame_options)
      end

      assert_match(/frame_options cannot set id/, error.message)
    end
  end

  def test_without_collapsible_the_detail_is_not_wrapped
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
      split.with_empty_detail { "NOTHING SELECTED" }
    end

    assert_no_selector(".split-view-component--collapsible, [data-split-state], .split-view-detail-pane", visible: :all)
    assert_no_selector("[data-controller~='split-view-collapse'], [data-split-view-collapse-target]", visible: :all)
    assert_no_selector("[data-split-view-empty]", visible: :all)
    assert_selector(".split-view-component > turbo-frame#inbox-detail", text: "NOTHING SELECTED", visible: :all)
  end

  def test_collapsible_starts_closed_with_the_frame_in_a_pane_with_close_and_back
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", collapsible: true)) do |split|
      split.with_master { "MASTER" }
      split.with_empty_detail { "NOTHING SELECTED" }
    end

    assert_selector(".split-view-component--collapsible[data-controller='split-view-collapse'][data-split-state='closed']")
    assert_selector(".split-view-detail-pane[data-split-view-collapse-target='pane'] " \
                    "turbo-frame#inbox-detail[data-split-view-collapse-target='frame']", visible: :all)
    assert_selector("[data-testid='split-view-close'][data-action='split-view-collapse#close']", text: "Close", visible: :all)
    assert_selector("[data-testid='split-view-back'][data-action='split-view-collapse#close']", text: "Back", visible: :all)
  end

  def test_collapsible_carries_a_hidden_loading_state_and_a_load_error_with_retry
    I18n.with_locale(:es) do
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", collapsible: true)) { |split| split.with_master { "MASTER" } }
    end

    loading = page.find(".split-view-detail-pane [role='status'] > [data-split-view-collapse-target='loading'][hidden]", visible: :all)
    assert_includes loading.native.text, "Cargando…"
    assert loading.has_css?("svg.split-view-spinner[aria-hidden='true']", visible: :all)
    error = page.find(".split-view-detail-pane > [data-split-view-collapse-target='error'][role='alert'][hidden]", visible: :all)
    assert_includes error.native.text, "No se pudo cargar el detalle."
    assert error.has_css?("[data-action='split-view-collapse#retry']", text: "Reintentar", visible: :all)
  end

  def test_the_loading_slot_replaces_the_default_spinner
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", collapsible: true)) do |split|
      split.with_master { "MASTER" }
      split.with_loading { "FETCHING THE RECORD" }
    end

    loading = page.find("[data-split-view-collapse-target='loading']", visible: :all)
    assert_includes loading.native.text, "FETCHING THE RECORD"
    assert_no_selector(".split-view-spinner", visible: :all)
  end

  def test_without_collapsible_there_is_no_loading_state
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) do |split|
      split.with_master { "MASTER" }
      split.with_loading { "FETCHING THE RECORD" }
    end

    assert_no_selector(".split-view-loading, .split-view-load-error, [role='status']", visible: :all)
  end

  # The controller opens the pane when the frame holds something other than
  # this marker, so an empty state must carry it or the pane opens on load.
  def test_collapsible_marks_the_empty_detail
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", collapsible: true)) do |split|
      split.with_master { "MASTER" }
      split.with_empty_detail { "NOTHING SELECTED" }
    end

    assert_selector("turbo-frame#inbox-detail > [data-split-view-empty]", text: "NOTHING SELECTED", visible: :all)
  end

  def test_collapsible_starts_open_on_a_server_rendered_detail
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", collapsible: true)) do |split|
      split.with_master { "MASTER" }
      split.with_detail { "DETAIL" }
    end

    assert_selector(".split-view-component--collapsible[data-split-state='open']")
    assert_no_selector("[data-split-view-empty]", visible: :all)
  end

  def test_collapsible_keeps_the_callers_controller_and_data
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", collapsible: true,
                                                 data: { controller: "host", testid: "split" })) do |split|
      split.with_master { "MASTER" }
    end

    assert_selector("[data-testid='split'][data-controller='split-view-collapse host']")
  end

  def test_without_the_new_options_the_container_is_as_before
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail")) { |split| split.with_master { "MASTER" } }

    container = page.find(".split-view-component")
    assert_equal "split-view-component", container[:class]
    assert_equal "--bali-split-master-width: 420px", container[:style]
    assert_nil container["data-controller"]
  end

  def test_master_width_equal_is_a_class_not_a_width
    [ :equal, "equal" ].each do |master_width|
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", master_width: master_width)) do |split|
        split.with_master { "MASTER" }
      end

      container = page.find(".split-view-component")
      assert_includes container[:class].split, "split-view-component--equal", master_width.inspect
      assert_no_match(/--bali-split-master-width/, container[:style].to_s, master_width.inspect)
    end
  end

  def test_master_width_rejects_other_keywords
    error = assert_raises(ArgumentError) { Bali::SplitView::Component.new(frame_id: "x", master_width: :half) }

    assert_match(/master_width must be :equal or a CSS length/, error.message)
  end

  def test_height_screen_fills_and_measures_its_top
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", height: :screen)) { |split| split.with_master { "MASTER" } }

    assert_selector(".split-view-component.split-view-component--full.split-view-component--screen[data-controller='split-view-screen']")
  end

  def test_height_screen_and_collapsible_share_the_controller_attribute
    render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", height: :screen, collapsible: true,
                                                 data: { controller: "host" })) { |split| split.with_master { "MASTER" } }

    assert_selector("[data-controller='split-view-collapse split-view-screen host'][data-split-state='closed']")
  end

  def test_height_takes_a_fixed_css_length
    %w[640px 40rem 70vh 80dvh].each do |height|
      render_inline(Bali::SplitView::Component.new(frame_id: "inbox-detail", height: height)) { |split| split.with_master { "MASTER" } }

      container = page.find(".split-view-component")
      assert_includes container[:class].split, "split-view-component--fixed", height
      assert_includes container[:class].split, "split-view-component--full", height
      assert_includes container[:style], "--bali-split-height: #{height}", height
      assert_nil container["data-controller"], height
    end
  end

  def test_height_rejects_what_is_not_a_keyword_or_a_length
    [ "tall", "640", "calc(100vh - 2rem)", :fill, 640 ].each do |height|
      error = assert_raises(ArgumentError, height.inspect) { Bali::SplitView::Component.new(frame_id: "x", height: height) }

      assert_match(/height must be one of :content, :full, :screen or a CSS length/, error.message)
    end
  end

  private

  def frame_tag_values(attribute)
    rendered_content[/<turbo-frame[^>]*>/].scan(/ #{attribute}="([^"]*)"/).flatten
  end
end
