# frozen_string_literal: true

require "test_helper"

class BaliSideMenuTriggerComponentTest < ComponentTestCase
  def test_renders_a_real_button
    render_inline(Bali::SideMenu::Trigger::Component.new)
    assert_selector("button[type='button']")
    assert_no_selector("label")
  end

  def test_points_at_the_default_side_menu
    render_inline(Bali::SideMenu::Trigger::Component.new)
    assert_selector(
      "button[aria-controls='#{Bali::SideMenu::Component::DEFAULT_ID}']" \
      "[data-side-menu-trigger-menu-id-value='#{Bali::SideMenu::Component::DEFAULT_ID}']"
    )
  end

  def test_points_at_a_custom_side_menu
    render_inline(Bali::SideMenu::Trigger::Component.new(menu_id: "reports-menu"))
    assert_selector("button[aria-controls='reports-menu']")
    assert_selector("button[data-side-menu-trigger-menu-id-value='reports-menu']")
  end

  def test_starts_collapsed_and_is_wired_to_the_trigger_controller
    render_inline(Bali::SideMenu::Trigger::Component.new)
    assert_selector("button[aria-expanded='false']")
    assert_selector("button[data-controller~='side-menu-trigger']")
    assert_selector("button[data-action~='click->side-menu-trigger#toggle']")
  end

  def test_has_a_translated_accessible_name
    render_inline(Bali::SideMenu::Trigger::Component.new)
    assert_selector("button[aria-label='#{I18n.t('bali_view.side_menu.trigger.toggle')}']")
  end

  def test_accessible_name_can_be_overridden
    render_inline(Bali::SideMenu::Trigger::Component.new('aria-label': "Open navigation"))
    assert_selector("button[aria-label='Open navigation']")
  end

  def test_renders_the_default_icon
    render_inline(Bali::SideMenu::Trigger::Component.new)
    assert_selector("button svg")
  end

  def test_content_replaces_the_icon
    render_inline(Bali::SideMenu::Trigger::Component.new) { "Menu" }
    assert_selector("button", text: "Menu")
  end

  def test_accepts_extra_classes_without_losing_the_base_ones
    render_inline(Bali::SideMenu::Trigger::Component.new(class: "lg:hidden"))
    assert_selector("button.btn.btn-ghost.btn-sm.lg\\:hidden")
  end

  def test_does_not_mutate_the_callers_data_hash
    data = { turbo_permanent: true }
    render_inline(Bali::SideMenu::Trigger::Component.new(data: data))
    assert_equal({ turbo_permanent: true }, data)
  end
end
