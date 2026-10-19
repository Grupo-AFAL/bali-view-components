# frozen_string_literal: true

require "test_helper"

# #1512 — the one topbar icon, counter A: the number is what is waiting on you, the dot says there
# are unread notices.
class BaliTopbarInboxComponentTest < ComponentTestCase
  def inbox(pending: 0, unread: 0, **options)
    I18n.with_locale(:es) do
      render_inline(Bali::Topbar::Inbox::Component.new(
                      badge: Bali::Inbox::Badge.new(pending: pending, unread: unread),
                      popover_url: "/inbox/popover", href: "/inbox", badge_url: "/inbox/badge", **options
                    ))
    end
  end

  # The link's name is its sr-only text; the pill and the dot beside it are aria-hidden.
  def accessible_name = page.find("a.bali-topbar-inbox-trigger .sr-only", visible: :all).text(:all).strip

  def test_no_badge_renders_nothing
    render_inline(Bali::Topbar::Inbox::Component.new(badge: nil, popover_url: "/p", href: "/inbox"))

    assert_no_selector(".bali-topbar-inbox")
  end

  def test_with_nothing_pending_or_unread_it_draws_neither
    inbox

    assert_no_selector(".bali-topbar-badge")
    assert_no_selector(".bali-topbar-inbox-dot")
    assert_equal "Bandeja", accessible_name
  end

  def test_pending_only_draws_the_count_and_names_it
    inbox(pending: 6)

    assert_selector(".bali-topbar-badge", text: "6")
    assert_no_selector(".bali-topbar-inbox-dot")
    assert_equal "Bandeja: 6 pendientes", accessible_name
  end

  def test_unread_only_draws_the_dot
    inbox(unread: 2)

    assert_no_selector(".bali-topbar-badge")
    assert_selector(".bali-topbar-inbox-dot")
    assert_equal "Bandeja: hay avisos sin leer", accessible_name
  end

  def test_both_draw_both
    inbox(pending: 1, unread: 2)

    assert_selector(".bali-topbar-badge", text: "1")
    assert_selector(".bali-topbar-inbox-dot")
    assert_equal "Bandeja: 1 pendiente, hay avisos sin leer", accessible_name
  end

  def test_a_hundred_pending_read_99_plus
    inbox(pending: 100)

    assert_selector(".bali-topbar-badge", text: "99+")
  end

  def test_the_pill_and_the_dot_are_hidden_from_the_name
    inbox(pending: 6, unread: 2)

    assert_selector('.bali-topbar-badge[aria-hidden="true"]')
    assert_selector('.bali-topbar-inbox-dot[aria-hidden="true"]')
  end

  # Not prefetched: a hover would GET the whole page — every provider — for a click that opens
  # the popover instead.
  def test_it_is_a_link_to_the_page_that_opens_a_dialog
    inbox

    assert_selector('a.bali-topbar-inbox-trigger[href="/inbox"][aria-haspopup="dialog"]' \
                    '[aria-expanded="false"][aria-controls="bali-inbox-panel"][data-turbo-prefetch="false"]')
    assert_selector('#bali-inbox-panel[role="dialog"][aria-label="Bandeja"][hidden]', visible: :all)
  end

  def test_the_popover_frame_waits_for_the_first_open
    inbox

    assert_selector("turbo-frame#bali-inbox-popover[target='_top']:not([src])", visible: :all)
    assert_selector("[data-topbar-inbox-popover-url-value='/inbox/popover']")
  end

  def test_the_skeleton_tabs_already_carry_the_badges_numbers
    inbox(pending: 6, unread: 2)

    assert_selector("#bali-inbox-popover", text: /Te toca\s*6/, visible: :all)
    assert_selector("#bali-inbox-popover", text: "2 sin leer", visible: :all)
  end

  def test_the_badge_lives_in_its_own_frame_with_the_signal_beside_it
    inbox(pending: 6)

    assert_selector("turbo-frame#bali-inbox-badge .bali-topbar-badge", text: "6")
    assert_selector("[data-topbar-inbox-badge-url-value='/inbox/badge']")
    assert_selector("##{Bali::Topbar::Inbox::Component::SIGNAL_ID}[data-topbar-inbox-target='signal']", visible: :all)
  end

  def test_stream_subscribes_to_the_owners_inbox_stream
    user = User.create!(name: "Ana")
    inbox(stream: user)

    assert_selector("turbo-cable-stream-source[signed-stream-name]", visible: :all)
  end
end
