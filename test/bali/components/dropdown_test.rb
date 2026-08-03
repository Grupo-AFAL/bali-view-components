# frozen_string_literal: true

require "test_helper"

class BaliDropdownComponentTest < ComponentTestCase
  def setup
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item 1" }
      c.with_item(href: "#") { "Item 2" }
    end
  end

  def test_renders_dropdown_container_with_daisyui_classes
    assert_selector(".dropdown")
  end

  def test_renders_trigger_button
    assert_selector(".btn", text: "Trigger")
  end

  def test_renders_dropdown_content_with_menu_class
    assert_selector(".dropdown-content.menu")
  end

  def test_renders_items_in_list_format
    assert_selector("li", count: 2)
  end

  # daisyUI's own default, and ActionsDropdown's, against Dropdown's old `:right`. The two
  # components had different defaults for the same menu; this is the one that survived.
  def test_alignments_defaults_to_start
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-start")
    assert_no_selector(".dropdown-end")
  end

  Bali::Dropdown::Component::ALIGNMENTS.each do |key, css|
    define_method("test_alignments_renders_#{key}") do
      render_inline(Bali::Dropdown::Component.new(align: key)) do |c|
        c.with_trigger { "Trigger" }
        c.with_item(href: "#") { "Item" }
      end
      assert_selector(".dropdown.#{css}")
    end
  end

  Bali::Dropdown::Component::DIRECTIONS.each do |key, css|
    define_method("test_directions_renders_#{key}") do
      render_inline(Bali::Dropdown::Component.new(direction: key)) do |c|
        c.with_trigger { "Trigger" }
        c.with_item(href: "#") { "Item" }
      end
      assert_selector(".dropdown.#{css}")
    end
  end

  def test_the_two_axes_compose
    render_inline(Bali::Dropdown::Component.new(direction: :top, align: :end)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-top.dropdown-end")
  end

  # `align: :left` used to mean "no class at all" and `:left` is now a DIRECTION, where it
  # means a menu opening sideways. Resolving it quietly would have moved the menu.
  Bali::Dropdown::Component::MOVED_ALIGNMENTS.each do |key, replacement|
    define_method("test_alignments_rejects_the_v2_spelling_#{key}") do
      error = assert_raises(ArgumentError) do
        Bali::Dropdown::Component.new(align: key)
      end
      assert_includes(error.message, replacement)
    end
  end

  def test_unknown_values_raise_naming_the_valid_ones
    error = assert_raises(ArgumentError) { Bali::Dropdown::Component.new(direction: :sideways) }
    assert_includes(error.message, ":top, :bottom, :left, :right")

    error = assert_raises(ArgumentError) { Bali::Dropdown::Component.new(width: :huge) }
    assert_includes(error.message, ":sm, :md, :lg, :xl")
  end

  # El chrome de un control de toolbar tenía que escribirse a mano en el call site porque el
  # enum no lo nombraba: `button`, `icon` y `ghost`, ninguno con borde.
  def test_trigger_outline_variant
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :outline) { "Columns" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector("[data-dropdown-target='trigger'].btn.btn-outline")
  end

  def test_hoverable_adds_dropdown_hover_class_when_hoverable
    render_inline(Bali::Dropdown::Component.new(hoverable: true)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown.dropdown-hover")
  end

  # A hover dropdown used to be the one shape with NO controller, so daisyUI opened it from
  # CSS and its trigger went on reporting `aria-expanded="false"` with the menu on screen.
  def test_hoverable_keeps_the_controller
    render_inline(Bali::Dropdown::Component.new(hoverable: true)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('.dropdown.dropdown-hover[data-controller="dropdown"]')
  end

  Bali::Dropdown::Component::WIDTHS.each do |key, css|
    define_method("test_width_#{key}") do
      render_inline(Bali::Dropdown::Component.new(width: key)) do |c|
        c.with_trigger { "Trigger" }
        c.with_item(href: "#") { "Item" }
      end
      assert_selector(".dropdown-content.#{css}")
    end
  end

  def test_width_defaults_to_md
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".dropdown-content.w-52")
  end

  def test_wide_raises_naming_its_replacement
    error = assert_raises(ArgumentError) { Bali::Dropdown::Component.new(wide: true) }
    assert_includes(error.message, "width: :xl")
  end

  def test_custom_content_renders_custom_html_content
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.tag.li { c.tag.span("Custom content", class: "custom-class") }
    end
    assert_selector("li span.custom-class", text: "Custom content")
  end

  def test_trigger_component_renders_with_tabindex_for_focus_behavior
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('[tabindex="0"]', text: "Trigger")
  end

  def test_trigger_component_renders_with_role_button_for_accessibility
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('[role="button"]', text: "Trigger")
  end

  def test_trigger_component_supports_icon_variant
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :icon) { "Icon" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".btn.btn-ghost.btn-circle", text: "Icon")
  end

  def test_trigger_component_supports_ghost_variant
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :ghost) { "Ghost" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".btn.btn-ghost", text: "Ghost")
  end

  def test_trigger_component_supports_custom_variant_with_no_btn_class
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger(variant: :custom, class: "my-custom-class") { "Custom" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector(".my-custom-class", text: "Custom")
    assert_no_selector(".btn", text: "Custom")
  end

  def test_accessibility_renders_menu_with_aria_label
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('ul[role="menu"][aria-label="Dropdown menu"]')
  end

  def test_accessibility_renders_items_with_proper_roles
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item 1" }
      c.with_item(href: "#") { "Item 2" }
    end
    assert_selector('li[role="none"]', count: 2)
    assert_selector('a[role="menuitem"]', count: 2)
  end

  def test_accessibility_renders_trigger_with_aria_haspopup_and_aria_expanded
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(href: "#") { "Item" }
    end
    assert_selector('[aria-haspopup="true"][aria-expanded="false"]', text: "Trigger")
  end

  def test_title_item_renders_a_menu_title_and_not_a_menuitem
    # Un encabezado AGRUPA items; contado como opción navegable, el lector de pantalla
    # anuncia una opción más de las que hay.
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(tag: :title, name: "Export filtered")
      c.with_item(href: "/movies.csv") { "CSV" }
    end

    assert_selector("span.menu-title", text: "Export filtered")
    assert_selector('[role="menuitem"]', count: 1)
    # Un span genérico NO es un hijo que `role="menu"` admita (solo menuitem/group/separator).
    # Presentacional deja de contar como hijo inválido sin sacarle el texto a un
    # `aria-describedby` que lo apunte.
    assert_selector('span.menu-title[role="presentation"]')
  end

  # `with_item(method: :delete)` used to hand `method:` straight to DeleteLink, which has no
  # such keyword: it landed in **options and came out as `<button method="delete">`, an
  # attribute a browser ignores. The verb travels in the `button_to` DeleteLink builds.
  def test_a_delete_item_does_not_paint_a_method_attribute
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(name: "Delete", href: "/movies/1", method: :delete)
    end

    assert_no_selector("[method='delete']")
    assert_selector("form[method='post'] input[name='_method'][value='delete']", visible: :all)
    assert_selector("button[role='menuitem']", text: "Delete")
  end

  # daisyUI paints the item on `.menu li > *`, so the <form> `button_to` wraps the button in
  # became the item and the button inside it a second, smaller one: Delete measured 192x49
  # with a 168x37 hover box inside it, against Edit's single 192x37. The form has to be out
  # of the box tree for the menu to have one metric.
  def test_a_delete_item_leaves_the_button_as_the_menu_item
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(name: "Delete", href: "/movies/1", method: :delete)
    end

    assert_selector("li > form.contents", visible: :all)
    assert_no_selector("li > form.inline-block", visible: :all)
  end

  def test_icon_is_one_keyword_for_both_kinds_of_item
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(name: "Edit", href: "/e", icon: "pencil")
      c.with_item(name: "Delete", href: "/d", method: :delete, icon: "trash")
    end

    assert_selector("a[role='menuitem'] svg")
    assert_selector("button[role='menuitem'] svg")
  end

  # The `icon_name:` shim lives in test/bali/deprecated_icon_name_test.rb, with the other six.

  # `name:` and `icon:` on a button item used to be painted as HTML attributes, so the only
  # way to label one was a block.
  def test_a_button_item_takes_a_name_and_an_icon
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(tag: :button, name: "Duplicate", icon: "copy",
                  data: { action: "thing#duplicate" })
    end

    assert_selector("button[role='menuitem'][type='button'][data-action='thing#duplicate'] svg")
    assert_selector("button[role='menuitem']", text: "Duplicate")
    assert_no_selector("button[name='Duplicate']")
  end

  # The menu is rendered in the same place, with the same roles, in both modes. What tells
  # the controller to portal it is one Stimulus value; the markup is not a second shape.
  def test_popover_mode_changes_a_value_and_not_the_markup
    render_inline(Bali::Dropdown::Component.new(popover: true)) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(name: "Edit", href: "/e")
    end

    assert_selector("div.dropdown[data-dropdown-popover-value='true']")
    assert_selector("div.dropdown > ul[role='menu'].dropdown-content.menu")
  end

  def test_popover_defaults_to_false
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(name: "Edit", href: "/e")
    end

    assert_selector("[data-dropdown-popover-value='false']")
  end

  # tippy's vocabulary for the same two axes. `center` is tippy's unsuffixed placement.
  def test_tippy_placement_follows_the_two_axes
    {
      {} => "bottom-start",
      { align: :end } => "bottom-end",
      { align: :center } => "bottom",
      { direction: :top, align: :end } => "top-end",
      { direction: :left } => "left-start",
      { direction: :right, align: :center } => "right"
    }.each do |kwargs, expected|
      render_inline(Bali::Dropdown::Component.new(**kwargs)) do |c|
        c.with_trigger { "Trigger" }
        c.with_item(name: "Edit", href: "/e")
      end

      assert_selector("[data-dropdown-placement-value='#{expected}']")
    end
  end

  def test_a_menu_of_only_titles_does_not_render
    # Un menú de puro encabezado no es un menú: destaparía un botón que no abre ninguna
    # opción para elegir.
    render_inline(Bali::Dropdown::Component.new) do |c|
      c.with_trigger { "Trigger" }
      c.with_item(tag: :title, name: "Export filtered")
    end

    assert_no_selector(".dropdown")
  end
end
