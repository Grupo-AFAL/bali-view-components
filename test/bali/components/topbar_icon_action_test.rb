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
