# frozen_string_literal: true

require "test_helper"

class Bali_SideMenu_ComponentTest < ComponentTestCase
  def setup
    @options = { current_path: "/" }
  end

  def component
    Bali::SideMenu::Component.new(**@options)
  end

  def test_renders_the_side_menu
    render_inline(component) do |c|
      c.with_list(title: "Comedor") do |list|
        list.with_item(name: "Item 1", href: "/movies")
      end
    end
    assert_selector(".side-menu-component")
    assert_selector("p.menu-label", text: "Comedor")
    assert_selector(".sidebar-menu")
    assert_selector("a[href='/movies']", text: "Item 1")
  end

  def test_renders_the_side_menu_with_icon
    render_inline(component) do |c|
      c.with_list(title: "Section title") do |list|
        list.with_item(name: "Item 1", href: "#", icon: "attachment")
      end
    end
    assert_selector(".side-menu-component")
    assert_selector("a > span.icon-component")
    assert_selector("a", text: "Item 1")
  end

  def test_when_not_authorized_does_not_render_the_link
    render_inline(component) do |c|
      c.with_list(title: "Section title") do |list|
        list.with_item(name: "item", href: "#", authorized: false)
      end
    end
    assert_selector(".side-menu-component")
    assert_no_selector("li > a")
  end

  def test_with_crud_match_renders_as_active_when_current_path_is_the_new_path
    @options[:current_path] = "/items/new"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "items", href: "/items", match: :crud)
      end
    end
    assert_selector("a.active", text: "items")
  end

  def test_with_crud_match_renders_as_active_when_current_path_is_the_item_show_path
    @options[:current_path] = "/items/123"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "items", href: "/items", match: :crud)
      end
    end
    assert_selector("a.active", text: "items")
  end

  def test_with_crud_match_renders_as_active_when_current_path_is_the_item_edit_path
    @options[:current_path] = "/items/123/edit"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "items", href: "/items", match: :crud)
      end
    end
    assert_selector("a.active", text: "items")
  end

  def test_with_crud_match_renders_as_active_when_current_path_is_the_item_index_path
    @options[:current_path] = "/items"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "items", href: "/items", match: :crud)
      end
    end
    assert_selector("a.active", text: "items")
  end

  def test_with_crud_match_renders_as_inactive_when_current_path_is_not_a_crud_action
    @options[:current_path] = "/items/dashboard"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "items", href: "/items", match: :crud)
      end
    end
    assert_no_selector("a.active", text: "items")
  end

  def test_with_starts_with_match_renders_as_active_when_current_path_starts_with_item_href
    @options[:current_path] = "/item"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "item root", href: "/item", match: :starts_with)
      end
    end
    assert_selector("a.active", text: "item root")
  end

  def test_with_starts_with_match_renders_as_inactive_when_href_is_included_within_current_path
    @options[:current_path] = "/section/item"
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "item root", href: "/item", match: :starts_with)
      end
    end
    assert_no_selector("a.active", text: "item root")
  end

  def test_with_partial_match_renders_an_active_link
    @options[:current_path] = "/section/item/menu"
    render_inline(component) do |c|
      c.with_list(title: "Section title") do |list|
        list.with_item(name: "item root", href: "/item", match: :partial)
        list.with_item(name: "item menu", href: "/section/item/menu")
      end
    end
    assert_selector("a.active", text: "item root")
    assert_selector("a.active", text: "item menu")
  end

  def test_with_exact_match_renders_an_active_link
    @options[:current_path] = "/item"
    render_inline(component) do |c|
      c.with_list(title: "Section title") do |list|
        list.with_item(name: "item root", href: "/item")
        list.with_item(name: "item 1", href: "/item/1")
      end
    end
    assert_selector("a.active", text: "item root")
    assert_no_selector("a.active", text: "item 1")
  end

  def test_passes_data_attributes_through_to_the_anchor_tag
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "Sign Out", href: "/logout", data: { turbo_method: :delete })
      end
    end
    assert_selector('a[data-turbo-method="delete"]', text: "Sign Out")
  end

  def test_renders_a_disabled_link
    render_inline(component) do |c|
      c.with_list(title: "Section title") do |list|
        list.with_item(name: "Item", href: "#", disabled: true)
      end
    end
    assert_selector('a[disabled="disabled"]', text: "Item")
  end

  def test_with_bottom_items_renders_bottom_items_outside_the_scrollable_area
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "Dashboard", href: "/dashboard")
      end
      c.with_bottom_item(name: "Profile", href: "/profile")
      c.with_bottom_item(name: "Sign Out", href: "/sign_out")
    end
    assert_selector("a", text: "Profile")
    assert_selector("a", text: "Sign Out")
  end

  def test_with_bottom_items_renders_bottom_items_with_icons
    render_inline(component) do |c|
      c.with_bottom_item(name: "Profile", href: "/profile", icon: "user")
    end
    assert_selector("a", text: "Profile")
  end

  def test_with_bottom_items_does_not_render_bottom_section_when_no_bottom_items_are_given
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: "Dashboard", href: "/dashboard")
      end
    end
    assert_no_selector(".border-t.border-base-200.shrink-0")
  end

  def test_with_bottom_items_skips_unauthorized_bottom_items
    render_inline(component) do |c|
      c.with_bottom_item(name: "Profile", href: "/profile", authorized: true)
      c.with_bottom_item(name: "Admin", href: "/admin", authorized: false)
    end
    assert_selector("a", text: "Profile")
    assert_no_selector("a", text: "Admin")
  end

  def test_with_bottom_items_marks_active_bottom_item_based_on_current_path
    @options[:current_path] = "/profile"
    render_inline(component) do |c|
      c.with_bottom_item(name: "Profile", href: "/profile")
      c.with_bottom_item(name: "Sign Out", href: "/sign_out")
    end
    assert_selector("a.active", text: "Profile")
    assert_no_selector("a.active", text: "Sign Out")
  end
end
