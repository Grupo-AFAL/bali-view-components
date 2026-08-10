# frozen_string_literal: true

require "test_helper"

class BaliTopbarIconActionComponentTest < ComponentTestCase
  def test_renders_a_labelled_icon_button
    render_inline(Bali::Topbar::IconAction::Component.new(icon: "bell", label: "Notifications"))

    assert_selector('button[type="button"].btn.btn-ghost.btn-sm.btn-square' \
                    '[aria-label="Notifications"][title="Notifications"]')
    assert_selector("button span.icon-component.size-5 svg")
  end

  def test_renders_a_link_when_given_href
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "bell", label: "Notifications", href: "/notifications"
                  ))

    assert_selector('a[href="/notifications"].btn.btn-square[aria-label="Notifications"]')
    assert_no_selector("button")
    assert_no_selector("a[type]")
  end

  def test_badge_true_draws_the_dot
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "bell", label: "Notifications", badge: true
                  ))

    assert_selector("button.relative span.bali-topbar-badge.bg-error[aria-hidden='true']")
  end

  def test_numeric_badge_draws_a_count_pill
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "bell", label: "Notifications", badge: 3
                  ))

    assert_selector("button.relative span.bali-topbar-badge .badge.badge-error.badge-xs",
                    text: "3")
  end

  # #995: the "> 99 ? '99+'" every host wrote by hand, packaged. Only Integer
  # badges are capped — a String is a count the host already formatted.
  def test_numeric_badge_above_max_count_renders_the_capped_form
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "inbox", label: "Inbox", badge: 128
                  ))

    assert_selector("span.bali-topbar-badge .badge", text: "99+")
    assert_no_selector("span.bali-topbar-badge .badge", text: "128")
  end

  def test_max_count_is_configurable
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "inbox", label: "Inbox", badge: 12, max_count: 9
                  ))

    assert_selector("span.bali-topbar-badge .badge", text: "9+")
  end

  def test_string_badge_is_never_capped
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "inbox", label: "Inbox", badge: "999"
                  ))

    assert_selector("span.bali-topbar-badge .badge", text: "999")
  end

  # #995: the current-section state. On a link it is also announced
  # (`aria-current="page"`); a button gets the visual state alone.
  def test_active_paints_the_active_state_and_announces_it_on_a_link
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "inbox", label: "Inbox", href: "/inbox", active: true
                  ))

    assert_selector('a.btn-active[aria-current="page"]')
  end

  def test_active_on_a_button_has_no_aria_current
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "inbox", label: "Inbox", active: true
                  ))

    assert_selector("button.btn-active")
    assert_no_selector("[aria-current]")
  end

  def test_inactive_carries_no_active_state
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "inbox", label: "Inbox", href: "/inbox"
                  ))

    assert_no_selector(".btn-active")
    assert_no_selector("[aria-current]")
  end

  def test_badge_id_names_the_turbo_stream_target
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "bell", label: "Notifications", badge: true,
                    badge_id: "notifications-badge"
                  ))

    assert_selector("span#notifications-badge.bali-topbar-badge")
  end

  def test_badge_id_without_badge_renders_an_empty_hidden_target
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "bell", label: "Notifications", badge_id: "notifications-badge"
                  ))

    assert_selector("span#notifications-badge[hidden]", visible: false)
    assert_selector("button.relative")
  end

  def test_no_badge_no_target_no_relative
    render_inline(Bali::Topbar::IconAction::Component.new(icon: "bell", label: "Help"))

    assert_no_selector(".bali-topbar-badge", visible: :all)
    assert_no_selector("button.relative")
  end

  def test_passes_through_options
    render_inline(Bali::Topbar::IconAction::Component.new(
                    icon: "bell", label: "Notifications",
                    class: "custom", data: { action: "notifications#open" }
                  ))

    assert_selector('button.btn.custom[data-action="notifications#open"]')
  end
end
