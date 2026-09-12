# frozen_string_literal: true

require "test_helper"

# Bali::Topbar::UserMenu is a preset of Bali::Dropdown (like ActionsDropdown), so the menu
# mechanics — controller, keyboard, roles — are asserted once in dropdown_test.rb. What this
# file asserts is the preset: the avatar+name trigger, the identity header, the item order,
# and the sign-out contract (#713: no default route, `:delete` by default, real form).
class BaliTopbarUserMenuComponentTest < ComponentTestCase
  def sign_out
    { href: "/logout" }
  end

  def test_it_is_a_dropdown
    assert_operator(Bali::Topbar::UserMenu::Component, :<, Bali::Dropdown::Component)
  end

  def test_renders_a_dropdown_aligned_to_the_end
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García", sign_out: sign_out))
    assert_selector("div.dropdown.dropdown-end.bali-topbar-user-menu")
    assert_selector('[data-controller="dropdown"]')
  end

  def test_trigger_carries_avatar_with_derived_initials_name_and_chevron
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García", sign_out: sign_out))

    assert_selector('[data-dropdown-target="trigger"] .avatar-placeholder', text: "AG")
    assert_selector('[data-dropdown-target="trigger"] span.hidden.md\\:inline',
                    text: "Ana García")
    assert_selector('[data-dropdown-target="trigger"] svg', count: 1) # the chevron
  end

  def test_trigger_uses_the_photo_when_avatar_url_is_given
    render_inline(Bali::Topbar::UserMenu::Component.new(
                    name: "Ana García", avatar_url: "/ana.jpg", sign_out: sign_out
                  ))
    assert_selector('[data-dropdown-target="trigger"] img[src="/ana.jpg"]')
  end

  def test_trigger_has_an_accessible_name_with_the_user_name
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García", sign_out: sign_out))
    assert_selector('[data-dropdown-target="trigger"][aria-label="User menu for Ana García"]')
  end

  def test_header_shows_name_and_email_and_is_not_a_menuitem
    render_inline(Bali::Topbar::UserMenu::Component.new(
                    name: "Ana García", email: "ana@example.com", sign_out: sign_out
                  ))

    assert_selector("span.menu-title.bali-topbar-user-menu-header", text: "Ana García")
    assert_selector("span.menu-title", text: "ana@example.com")
    assert_selector('span.menu-title[role="presentation"]')
    assert_no_selector('[role="menuitem"].bali-topbar-user-menu-header')
  end

  def test_header_omits_the_email_line_when_absent
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García", sign_out: sign_out))
    assert_selector(".bali-topbar-user-menu-header span", count: 1)
  end

  def test_items_render_between_header_and_sign_out
    render_inline(Bali::Topbar::UserMenu::Component.new(
                    name: "Ana García", sign_out: sign_out
                  )) do |menu|
      menu.with_item(name: "Profile", href: "/profile")
      menu.with_item(name: "Settings", href: "/settings")
    end

    texts = page.all("ul li").map(&:text)
    assert_match(/Ana García/, texts.first)
    assert_match(/Profile/, texts[1])
    assert_match(/Settings/, texts[2])
    assert_match(/Sign out/, texts.last)
  end

  def test_without_sign_out_there_is_no_sign_out_item
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García")) do |menu|
      menu.with_item(name: "Profile", href: "/profile")
    end

    assert_no_selector(".bali-topbar-sign-out")
    assert_no_text("Sign out")
  end

  # 713-D1: `method: :delete` is the hash's default and routes through DeleteLink's
  # `button_to` — a real form that cannot degrade to a GET without JavaScript.
  def test_sign_out_is_a_real_delete_form_without_confirm
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García", sign_out: sign_out))

    assert_selector('form[action="/logout"][method="post"]')
    assert_selector('form input[name="_method"][value="delete"]', visible: false)
    assert_selector("form button.bali-topbar-sign-out", text: "Sign out")
    assert_selector("form button svg") # log-out icon
    assert_no_selector("form[data-turbo-confirm]")
  end

  def test_sign_out_takes_a_custom_label_and_confirm
    render_inline(Bali::Topbar::UserMenu::Component.new(
                    name: "Ana García",
                    sign_out: { href: "/logout", name: "Log out", confirm: "Leave?" }
                  ))

    assert_selector("form button", text: "Log out")
    assert_selector('form[data-turbo-confirm="Leave?"]')
  end

  def test_sign_out_with_another_method_becomes_a_button_to_form
    render_inline(Bali::Topbar::UserMenu::Component.new(
                    name: "Ana García", sign_out: { href: "/logout", method: :post }
                  ))

    # #641 (announced in v3.1): every non-GET item is a real `button_to` form —
    # an `<a data-turbo-method>` degrades to GET without JS. `:post` keeps the
    # text-error styling it had as a link.
    assert_selector('form[action="/logout"] button.text-error', text: "Sign out")
    assert_no_selector("a[data-turbo-method]")
  end

  def test_sign_out_without_href_raises
    error = assert_raises(ArgumentError) do
      Bali::Topbar::UserMenu::Component.new(name: "Ana García", sign_out: { method: :delete })
    end
    assert_match(/sign_out/, error.message)
  end

  def test_renders_nothing_with_no_items_and_no_sign_out
    # The header is presentational and does not count towards Dropdown#render?:
    # a user menu with nothing actionable in it renders no menu at all.
    render_inline(Bali::Topbar::UserMenu::Component.new(name: "Ana García"))
    assert_no_selector(".dropdown")
  end

  def test_items_keep_the_dropdown_lambda_powers
    render_inline(Bali::Topbar::UserMenu::Component.new(
                    name: "Ana García", sign_out: sign_out
                  )) do |menu|
      menu.with_item(name: "Profile", href: "/profile", icon: "user")
    end

    assert_selector('a[role="menuitem"] svg')
  end
end
