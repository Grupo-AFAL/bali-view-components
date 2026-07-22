# frozen_string_literal: true

require "test_helper"

class BaliViewSwitchComponentTest < ComponentTestCase
  def render_switch(**component_options)
    render_inline(Bali::ViewSwitch::Component.new(aria_label: "Views", **component_options)) do |switch|
      switch.with_view(name: "List", icon: "list", href: "/projects/list", active: true)
      switch.with_view(name: "Board", icon: "grid", href: "/projects/board")
    end
  end

  def test_renders_a_join_group_with_role_and_aria_label
    render_switch
    assert_selector("div.view-switch-component.join[role='group'][aria-label='Views']")
  end

  def test_renders_one_link_per_view
    render_switch
    assert_selector("a.btn.join-item", count: 2)
    assert_selector("a[href='/projects/list']", text: "List")
    assert_selector("a[href='/projects/board']", text: "Board")
  end

  def test_active_view_gets_primary_classes_and_aria_pressed_true
    render_switch
    assert_selector("a.btn-active.btn-primary[href='/projects/list'][aria-pressed='true']")
  end

  def test_inactive_view_gets_outline_classes_and_aria_pressed_false
    render_switch
    assert_selector("a.btn-outline[href='/projects/board'][aria-pressed='false']")
    assert_no_selector("a.btn-active[href='/projects/board']")
  end

  def test_renders_an_icon_per_view
    render_switch
    assert_selector("a[href='/projects/list'] span.icon-component svg")
  end

  def test_labeled_views_add_gap_between_icon_and_text
    render_switch
    assert_selector("a[href='/projects/list'][class*='gap-1.5']")
    assert_no_selector("a.btn-square")
  end

  def test_default_size_is_sm
    render_switch
    assert_selector("a.btn.btn-sm", count: 2)
  end

  def test_size_md_adds_no_size_class
    render_switch(size: :md)
    assert_selector("a.btn", count: 2)
    assert_no_selector("a.btn-sm")
  end

  def test_size_xs_is_applied
    render_switch(size: :xs)
    assert_selector("a.btn.btn-xs", count: 2)
  end

  def test_active_is_autodetected_from_the_request_path
    with_request_url "/studios" do
      render_inline(Bali::ViewSwitch::Component.new(aria_label: "Views")) do |switch|
        switch.with_view(name: "List", icon: "list", href: "/movies")
        switch.with_view(name: "Board", icon: "grid", href: "/studios")
      end
    end
    assert_selector("a.btn-active.btn-primary[href='/studios'][aria-pressed='true']")
    assert_selector("a.btn-outline[href='/movies'][aria-pressed='false']")
  end

  def test_autodetection_ignores_the_query_string
    with_request_url "/studios?page=2" do
      render_inline(Bali::ViewSwitch::Component.new(aria_label: "Views")) do |switch|
        switch.with_view(name: "Board", icon: "grid", href: "/studios")
      end
    end
    assert_selector("a.btn-active.btn-primary[aria-pressed='true']")
  end

  def test_explicit_active_false_overrides_autodetection
    with_request_url "/studios" do
      render_inline(Bali::ViewSwitch::Component.new(aria_label: "Views")) do |switch|
        switch.with_view(name: "Board", icon: "grid", href: "/studios", active: false)
      end
    end
    assert_selector("a.btn-outline[aria-pressed='false']")
    assert_no_selector("a.btn-active")
  end

  def test_icon_only_renders_square_buttons_without_text
    render_switch(icon_only: true)
    assert_selector("a.btn-square", count: 2)
    assert_no_text("List")
    assert_no_text("Board")
  end

  def test_icon_only_uses_the_name_as_native_tooltip_and_accessible_label
    render_switch(icon_only: true)
    assert_selector("a[href='/projects/list'][title='List'][aria-label='List']")
    assert_selector("a[href='/projects/board'][title='Board'][aria-label='Board']")
  end

  def test_view_options_passthrough_supports_turbo_action
    render_inline(Bali::ViewSwitch::Component.new(aria_label: "Views")) do |switch|
      switch.with_view(name: "List", icon: "list", href: "/projects/list",
                       active: true, data: { turbo_action: "replace" })
    end
    assert_selector("a[data-turbo-action='replace']")
  end

  def test_view_class_passthrough_is_appended_to_button_classes
    render_inline(Bali::ViewSwitch::Component.new(aria_label: "Views")) do |switch|
      switch.with_view(name: "List", icon: "list", href: "/projects/list",
                       active: true, class: "custom-view")
    end
    assert_selector("a.btn.join-item.custom-view")
  end

  def test_container_options_passthrough
    render_inline(Bali::ViewSwitch::Component.new(
      aria_label: "Views", class: "shrink-0", data: { testid: "switch" }
    )) do |switch|
      switch.with_view(name: "List", icon: "list", href: "/projects/list", active: true)
    end
    assert_selector("div.view-switch-component.join.shrink-0[data-testid='switch']")
  end
end
