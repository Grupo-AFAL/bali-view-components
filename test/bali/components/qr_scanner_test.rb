# frozen_string_literal: true

require "test_helper"

class BaliQrScannerComponentTest < ComponentTestCase
  def test_renders_the_viewfinder_and_mounts_the_controller
    render_inline(Bali::QrScanner::Component.new)

    assert_selector("div.qr-scanner-component[data-controller='qr-scanner']")
    assert_selector("video.qr-scanner-video[data-qr-scanner-target='video']")
  end

  # Every state is in the document from the first render. The controller shows
  # one by taking `hidden` off it, so a state built on demand would be a state
  # no host can style and no spec can find.
  def test_renders_every_panel
    render_inline(Bali::QrScanner::Component.new)

    Bali::QrScanner::Component::PANELS.each do |state|
      assert_selector("[data-qr-scanner-panel='#{state}']", visible: :all)
    end
  end

  # `scanning` is the state with no panel: the camera picture is the state.
  def test_scanning_has_no_panel
    render_inline(Bali::QrScanner::Component.new)

    assert_no_selector("[data-qr-scanner-panel='scanning']", visible: :all)
  end

  # Only the initial state renders without `hidden`. The rest are present and
  # hidden — which is what the Cypress spec measures as visibility.
  def test_only_the_initial_panel_is_visible
    render_inline(Bali::QrScanner::Component.new)

    assert_selector("[data-qr-scanner-panel='requesting']:not(.hidden)", visible: :all)
    assert_selector("[data-qr-scanner-panel='idle'].hidden", visible: :all)
    assert_selector("[data-qr-scanner-panel='denied'].hidden", visible: :all)
  end

  # Without JavaScript the initial state is the last thing the visitor sees, so
  # it has to be the one that explains itself: a spinner that never resolves is
  # worse than a button that was never pressed.
  def test_autostart_false_starts_on_idle
    render_inline(Bali::QrScanner::Component.new(autostart: false))

    assert_selector(".qr-scanner-component[data-qr-scanner-state='idle']")
    assert_selector("[data-qr-scanner-panel='idle']:not(.hidden)", visible: :all)
    assert_selector("[data-qr-scanner-panel='requesting'].hidden", visible: :all)
  end

  def test_autostart_true_starts_on_requesting
    render_inline(Bali::QrScanner::Component.new)

    assert_selector(".qr-scanner-component[data-qr-scanner-state='requesting']")
  end

  def test_defaults_to_the_rear_camera_and_stops_on_the_first_code
    render_inline(Bali::QrScanner::Component.new)

    assert_selector("[data-qr-scanner-camera-value='environment']")
    assert_selector("[data-qr-scanner-stop-on-scan-value='true']")
    assert_selector("[data-qr-scanner-autostart-value='true']")
    assert_selector("[data-qr-scanner-highlight-value='true']")
  end

  def test_passes_the_options_through_to_the_controller
    render_inline(
      Bali::QrScanner::Component.new(camera: :user, stop_on_scan: false, highlight: false)
    )

    assert_selector("[data-qr-scanner-camera-value='user']")
    assert_selector("[data-qr-scanner-stop-on-scan-value='false']")
    assert_selector("[data-qr-scanner-highlight-value='false']")
  end

  def test_unknown_camera_raises
    error = assert_raises(ArgumentError) { Bali::QrScanner::Component.new(camera: :rear) }

    assert_match(/unknown camera :rear/, error.message)
    assert_match(/:environment, :user/, error.message)
  end

  # The panels carry the buttons, so they must not be inert while hidden — but
  # more to the point, all three retry paths are one action.
  def test_every_panel_button_restarts_the_camera
    render_inline(Bali::QrScanner::Component.new)

    assert_selector("[data-qr-scanner-panel='idle'] button[data-action='qr-scanner#start']",
                    visible: :all)
    assert_selector("[data-qr-scanner-panel='scanned'] button[data-action='qr-scanner#start']",
                    visible: :all)
    assert_selector("[data-qr-scanner-panel='denied'] button[data-action='qr-scanner#start']",
                    visible: :all)
  end

  def test_renders_the_default_hint
    render_inline(Bali::QrScanner::Component.new)

    assert_selector(".qr-scanner-hint", text: I18n.t("bali_view.qr_scanner.hint"))
  end

  def test_hint_can_be_overridden_or_dropped
    render_inline(Bali::QrScanner::Component.new(hint: "Scan the label on the box"))
    assert_selector(".qr-scanner-hint", text: "Scan the label on the box")

    render_inline(Bali::QrScanner::Component.new(hint: false))
    assert_no_selector(".qr-scanner-hint")
  end

  def test_html_options_reach_the_container_without_dropping_the_controller
    render_inline(Bali::QrScanner::Component.new(class: "mx-auto", id: "checkin-scanner"))

    assert_selector("#checkin-scanner.qr-scanner-component.mx-auto[data-controller='qr-scanner']")
  end

  # A host that adds its own data attributes must not lose the ones that mount
  # the controller.
  def test_host_data_attributes_merge_with_the_controller_data
    render_inline(Bali::QrScanner::Component.new(data: { testid: "scanner" }))

    assert_selector("[data-testid='scanner'][data-controller='qr-scanner']")
  end

  # The live region is what a screen reader has instead of the picture: the
  # states replace one another inside it, so the transition is announced once.
  def test_panels_live_in_a_polite_live_region
    render_inline(Bali::QrScanner::Component.new)

    assert_selector(".qr-scanner-states[aria-live='polite']", visible: :all)
  end

  # iOS Safari takes an unmuted, non-inline video fullscreen the moment it
  # plays. qr-scanner sets both itself, but only once it has loaded.
  def test_video_plays_inline_and_muted
    render_inline(Bali::QrScanner::Component.new)

    assert_selector("video[playsinline][muted]", visible: :all)
  end
end
