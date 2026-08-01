# frozen_string_literal: true

require "test_helper"

class BaliTopbarComponentTest < ComponentTestCase
  def test_renders_the_topbar_container
    render_inline(Bali::Topbar::Component.new)
    assert_selector(".bali-topbar")
  end

  def test_uses_shared_chrome_height_for_alignment_with_side_menu_brand_row
    render_inline(Bali::Topbar::Component.new)
    assert_selector(".bali-topbar.bali-chrome-height")
  end

  def test_renders_brand_when_provided
    render_inline(Bali::Topbar::Component.new) do |topbar|
      topbar.with_brand { "ACME" }
    end
    assert_selector(".bali-topbar-brand", text: "ACME")
  end

  def test_does_not_render_brand_when_not_provided
    render_inline(Bali::Topbar::Component.new)
    assert_no_selector(".bali-topbar-brand")
  end

  def test_renders_search_when_provided
    render_inline(Bali::Topbar::Component.new) do |topbar|
      topbar.with_search { "<input class='search'/>".html_safe }
    end
    assert_selector("input.search")
  end

  def test_renders_actions_when_provided
    render_inline(Bali::Topbar::Component.new) do |topbar|
      topbar.with_action { "<button>Bell</button>".html_safe }
      topbar.with_action { "<button>Help</button>".html_safe }
    end
    assert_selector("button", text: "Bell")
    assert_selector("button", text: "Help")
  end

  def test_renders_user_menu_when_provided
    render_inline(Bali::Topbar::Component.new) do |topbar|
      topbar.with_user_menu { "<div class='avatar-stub'>AG</div>".html_safe }
    end
    assert_selector(".avatar-stub", text: "AG")
  end

  def test_renders_a_header_landmark
    # The topbar is the page's banner region. AppLayout renders it as a sibling
    # of <main>, so <header> maps to role="banner" with no explicit role.
    render_inline(Bali::Topbar::Component.new)
    assert_selector("header.bali-topbar")
  end

  def test_renders_mobile_trigger_by_default
    render_inline(Bali::Topbar::Component.new)
    assert_selector(
      "button[aria-controls='#{Bali::SideMenu::Component::DEFAULT_ID}']"
    )
  end

  def test_does_not_render_mobile_trigger_when_nil
    render_inline(Bali::Topbar::Component.new(menu_id: nil))
    assert_no_selector("button[aria-controls]")
  end

  def test_uses_custom_menu_id
    render_inline(Bali::Topbar::Component.new(menu_id: "custom-id"))
    assert_selector("button[aria-controls='custom-id']")
    assert_selector("button[data-side-menu-trigger-menu-id-value='custom-id']")
  end

  def test_mobile_trigger_has_aria_label
    render_inline(Bali::Topbar::Component.new)
    assert_selector("button[aria-label]")
  end

  def test_mobile_trigger_is_a_real_button_not_a_label
    # A <label> for a `display: none` checkbox is unreachable by keyboard, which
    # is what made the sidebar mouse-only on mobile before v3.
    render_inline(Bali::Topbar::Component.new)
    assert_no_selector("label")
    assert_selector("button[type='button'][aria-expanded='false']")
  end

  def test_mobile_trigger_is_hidden_on_large_screens
    render_inline(Bali::Topbar::Component.new)
    assert_selector("button.lg\\:hidden[aria-controls]")
  end

  def test_accepts_custom_classes
    render_inline(Bali::Topbar::Component.new(class: "custom-topbar"))
    assert_selector(".bali-topbar.custom-topbar")
  end

  def test_passes_through_data_attributes
    render_inline(Bali::Topbar::Component.new(data: { controller: "theme" }))
    assert_selector(".bali-topbar[data-controller='theme']")
  end
end
