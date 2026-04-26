# frozen_string_literal: true

require "test_helper"

class BaliTopbarComponentTest < ComponentTestCase
  def test_renders_the_topbar_container
    render_inline(Bali::Topbar::Component.new)
    assert_selector(".bali-topbar")
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

  def test_renders_mobile_trigger_label_by_default
    render_inline(Bali::Topbar::Component.new)
    assert_selector("label[for='#{Bali::SideMenu::Component::MOBILE_TRIGGER_ID}']")
  end

  def test_does_not_render_mobile_trigger_when_nil
    render_inline(Bali::Topbar::Component.new(mobile_trigger_id: nil))
    assert_no_selector("label.lg\\:hidden")
  end

  def test_uses_custom_mobile_trigger_id
    render_inline(Bali::Topbar::Component.new(mobile_trigger_id: "custom-id"))
    assert_selector("label[for='custom-id']")
  end

  def test_mobile_trigger_has_aria_label
    render_inline(Bali::Topbar::Component.new)
    assert_selector("label[aria-label]")
  end

  def test_mobile_trigger_does_not_use_role_button_polyfill
    # role="button" + tabindex on a <label> is an a11y anti-pattern: the label
    # already toggles the checkbox on click, but Space/Enter wouldn't work.
    render_inline(Bali::Topbar::Component.new)
    assert_no_selector("label[role='button']")
    assert_no_selector("label[tabindex]")
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
