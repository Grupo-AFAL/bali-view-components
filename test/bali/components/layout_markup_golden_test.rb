# frozen_string_literal: true

require "test_helper"

# The markup of the application layout, byte for byte: AppLayout, SideMenu, Command, Topbar,
# Tooltip and Icon, across their previews and the cases the previews leave out. Every page of
# every host renders these, so their rendering is tuned for speed, and a selector-based test
# passes markup that moved a space or lost an escape. Each case's HTML is compared whole
# against a file in test/fixtures/layout_markup.
#
# After a deliberate markup change, rewrite the files and review their diff:
#   GOLDEN=update bin/rails test test/bali/components/layout_markup_golden_test.rb
class LayoutMarkupGoldenTest < ComponentTestCase
  DIR = Bali::Engine.root.join("test/fixtures/layout_markup")
  COMPONENTS = Bali::Engine.root.join("app/components").to_s

  # Lucide's paths belong to lucide-rails: each body becomes the icon's name, so bumping the
  # gem does not turn this red, and an icon swapped for another still does. Names that share
  # a body share the marker.
  LUCIDE_NAMES = LucideRails::IconProvider.memory
                                          .group_by { |_name, body| body }
                                          .transform_values { |pairs| pairs.map(&:first).sort.join(" ") }
  LUCIDE_SVG = %r{(<svg [^>]*class="lucide-icon"[^>]*>)(.*?)(</svg>)}m

  CASES = Set.new

  def self.golden(name, &block)
    raise ArgumentError, "Two golden cases named #{name} would share one file" unless CASES.add?(name)

    test("#{name} renders the golden markup") do
      html = I18n.with_locale(:en) { instance_exec(&block) }
      assert_golden(name, html)
    end
  end

  def self.preview(preview_class, example, variant = nil, **params)
    golden("previews/#{preview_class.preview_name.delete_prefix('bali/').chomp('/')}/#{[ example, variant ].compact.join('-')}") do
      render_preview_example(preview_class, example, **params)
    end
  end

  test "every golden file belongs to a case" do
    files = Dir[DIR.join("**/*.html")].map { |path| path.delete_prefix("#{DIR}/").delete_suffix(".html") }
    assert_empty(files - CASES.to_a, "Golden files with no case; delete them")
  end

  Bali::SideMenu::Preview.examples.each { |example| preview(Bali::SideMenu::Preview, example) }
  preview(Bali::SideMenu::Preview, "default", "collapsible", collapsible: true)
  preview(Bali::SideMenu::Preview, "reveal_current", "fixed", fixed: true)
  preview(Bali::SideMenu::Preview, "with_bottom_items", "collapsible", collapsible: true)
  preview(Bali::SideMenu::Preview, "with_bottom_groups", "collapsible", collapsible: true, current_path: "/settings")
  Bali::Command::Preview.examples.each { |example| preview(Bali::Command::Preview, example) }
  Bali::Tooltip::Preview.examples.each { |example| preview(Bali::Tooltip::Preview, example) }
  Bali::Icon::Preview.examples.each { |example| preview(Bali::Icon::Preview, example) }
  Bali::AppLayout::Preview.examples.each { |example| preview(Bali::AppLayout::Preview, example) }
  preview(Bali::AppLayout::Preview, "default", "bare", collapsible: false, modal: false, drawer: false)
  preview(Bali::AppLayout::Preview, "with_topbar", "banner_and_flash", show_banner: true, flash_notice: "Saved & sent")
  # six_actions carries a FeedbackWidget token signed with this checkout's secret and the clock.
  (Bali::Topbar::Preview.examples - %w[six_actions]).each { |example| preview(Bali::Topbar::Preview, example) }

  golden("icon/sources") do
    # A mapped Bali name, a Lucide name, a kept icon, and a Lucide name a host also
    # registered: Lucide still wins it.
    with_custom_icons("golden-custom" => '<svg viewBox="0 0 1 1"><rect width="1"/></svg>',
                      "user" => '<svg viewBox="0 0 1 1"><circle r="1"/></svg>') do
      %w[edit arrow-left visa golden-custom user edit].map { |name| icon(name) }.join("\n")
    end
  end

  golden("icon/sizes") do
    [ nil, :small, :medium, :large, 24, 24.6, 20, "small" ].map { |size| icon("user", size: size) }
      .push(icon("visa", size: :large), icon("user"), icon("user", size: 20))
      .join("\n")
  end

  golden("icon/unknown_size") do
    Bali.deprecator.silence { icon("user", size: :sm) }
  end

  golden("icon/attributes") do
    [
      icon("user", id: "the-icon", class: 'text-info x"y <z> & w'),
      icon("user", style: "color: red", size: 24),
      icon("user", style: nil, id: nil, class: nil),
      icon("user", data: { controller: "golden", golden_value: '<&>"' }, aria: { label: "A & B" }),
      icon("user", title: %("5 > 3" & 'q'), hidden: true),
      icon("user", title: %(<b class="x">safe</b>).html_safe),
      icon("user", "aria-hidden": false),
      icon("user", "aria-hidden" => "false"),
      icon("user", class: %w[a b]),
      icon("user", class: %(<b>"x"</b>).html_safe),
      icon("user", style: %(font-family: "A&B").html_safe),
      icon("user", style: %(content: "<x>")),
      icon("user", "aria-hidden": "true"),
      icon("user", "aria-hidden": nil),
      icon("user", tag_name: :div),
      icon("user", tag_name: "i"),
      icon("visa", class: "size-6", tag_name: :div)
    ].join("\n")
  end

  golden("icon/unknown_names") do
    %w[definitely-not-an-icon arrow_left money-bill-wave].map do |name|
      icon(name)
    rescue Bali::Icon::Options::IconNotAvailable => error
      "#{error.class}: #{error.message}"
    end.join("\n")
  end

  golden("tooltip/options") do
    [
      render_html(Bali::Tooltip::Component.new) { |t| t.with_trigger { "Hover" }; "Tip" },
      render_html(Bali::Tooltip::Component.new(placement: :right, trigger_event: "click", append_to: :parent,
                                               trigger_label: %(Help & "more"), id: "tip", class: "a b",
                                               data: { golden: "<x>" })) do |t|
        t.with_trigger { icon("circle-help") }
        %(Content <b>escaped</b> & "quoted")
      end,
      render_html(Bali::Tooltip::Component.new(placement: :diagonal)) do |t|
        t.with_trigger { "<a href='#'>raw</a>".html_safe }
        "<em>safe</em>".html_safe
      end
    ].join("\n")
  end

  golden("side_menu/badges") do
    expandable = side_menu(current_path: "/inbox") do |menu|
      menu.with_list(title: "Work", badge: "<2> & 3", badge_color: :error) do |list|
        list.with_item(name: "Inbox", href: "/inbox", icon: "inbox", badge: 3)
        list.with_item(name: "Drafts", href: "/drafts", badge: %(<new> & "hot"), badge_color: :warning)
        %i[primary secondary accent success info pink].each do |color|
          list.with_item(name: "Badge #{color}", href: "/#{color}", badge: color, badge_color: color)
        end
        list.with_item(name: "Group", icon: "folder", badge: 7) do |group|
          group.with_item(name: "Child", href: "/inbox", badge: 1)
        end
      end
    end
    dropdown = side_menu(current_path: "/inbox", group_behavior: :dropdown) do |menu|
      menu.with_list(title: "Dropdown") do |list|
        list.with_item(name: "Menu", badge: "9+") do |group|
          group.with_item(name: "Child", href: "/elsewhere", icon: "star")
        end
      end
    end
    [ expandable, dropdown ].join("\n")
  end

  golden("side_menu/targets") do
    side_menu(current_path: "/docs") do |menu|
      menu.with_list do |list|
        list.with_item(name: "Docs", href: "/docs", target: "_blank", icon: "book")
        list.with_item(name: "Same tab", href: "/same", target: "_self")
        list.with_item(name: "External", href: "https://example.com/a?b=1&c=2", target: "_blank")
        list.with_item(name: "Parent", href: "/parent", target: "_blank", icon: "folder") do |group|
          group.with_item(name: "Docs child", href: "/docs", target: "_blank", icon: "file")
          group.with_item(name: "Other", href: "/other")
        end
      end
      menu.with_bottom_item(name: "Help", href: "/help", target: "_blank", icon: "circle-help")
    end
  end

  golden("side_menu/disabled") do
    side_menu(current_path: "/reports") do |menu|
      menu.with_list do |list|
        list.with_item(name: "Reports", href: "/reports", disabled: true, icon: "chart-bar")
        list.with_item(name: "No href", icon: "ban")
        list.with_item(name: "Blank href", href: "")
        list.with_item(name: "Forced", href: "/x", disabled: true, active: true)
        list.with_item(name: "Hidden", href: "/hidden", authorized: false)
        list.with_item(name: "Group", icon: "folder") do |group|
          group.with_item(name: "Disabled match", href: "/reports", disabled: true)
          group.with_item(name: "Enabled", href: "/enabled")
        end
      end
    end
  end

  golden("side_menu/dropdown_mode") do
    side_menu(current_path: "/team/members", group_behavior: :dropdown, collapsible: true) do |menu|
      menu.with_list(title: "Team") do |list|
        list.with_item(name: "Team", href: "/team", icon: "users") do |group|
          group.with_item(name: "Members", href: "/team/members", icon: "user")
          group.with_item(name: "Invites", href: "/team/invites", target: "_blank")
        end
        list.with_item(name: "Settings", icon: "settings", class: "host-class") do |group|
          group.with_item(name: "General", href: "/settings")
        end
        list.with_item(name: "Here", href: "/team/members") do |group|
          group.with_item(name: "Elsewhere", href: "/elsewhere")
        end
        list.with_item(name: "Leaf", href: "/leaf", icon: "leaf")
      end
    end
  end

  [ false, true ].each do |collapsible|
    %i[expandable dropdown].each do |behavior|
      golden("side_menu/three_levels-#{behavior}#{'-collapsible' if collapsible}") do
        side_menu(current_path: "/org/units/7/edit", group_behavior: behavior, collapsible: collapsible) do |menu|
          menu.with_list(title: "Organization") do |list|
            list.with_item(name: "Organization", icon: "building") do |org|
              org.with_item(name: "Units", href: "/org/units", icon: "boxes", match: :crud) do |units|
                units.with_item(name: "All units", href: "/org/units/index", match: :exact)
                units.with_item(name: "Archived", href: "/org/units/archived")
              end
              org.with_item(name: "People", href: "/org/people") do |people|
                people.with_item(name: "Active", href: "/org/people/active")
              end
            end
            list.with_item(name: "Deep", icon: "layers") do |deep|
              deep.with_item(name: "Middle") do |middle|
                middle.with_item(name: "Leaf", href: "/org/units/7/edit", icon: "leaf")
                middle.with_item(name: "Sibling", href: "/org/units/8")
              end
            end
            # A middle item with a link of its own is one its parent asks before it renders.
            list.with_item(name: "Linked", icon: "link") do |linked|
              linked.with_item(name: "Linked middle", href: "/org/linked") do |middle|
                middle.with_item(name: "Linked leaf", href: "/org/units/7/edit")
              end
            end
            list.with_item(name: "Home", href: "/", icon: "house")
          end
        end
      end
    end
  end

  golden("side_menu/collapsed_rail") do
    side_menu(current_path: "/b", collapsible: true, brand: "Brand & Co") do |menu|
      menu.with_list(title: "Rail") do |list|
        list.with_item(name: "Alpha", href: "/a", icon: "star")
        list.with_item(name: "beta", href: "/b")
        list.with_item(name: "Content", href: "/c") { "Custom & <content>" }
        list.with_item(href: "/nameless", icon: "circle")
        list.with_item(name: "", href: "/empty")
        list.with_item(name: "Kept", href: "/kept", icon: "visa")
        list.with_item(href: "/nothing")
        list.with_item(name: 2026, href: "/year")
        list.with_item(name: :symbol_name, href: "/symbol", icon: "star")
        list.with_item(name: "Symbol target", href: "/symbol-target", target: :_blank)
        list.with_item(name: "Empty target", href: "/empty-target", target: "")
        list.with_item(name: "Mapped", href: "/mapped", icon: "edit")
        list.with_item(name: "Group", href: "/group") do |group|
          group.with_item(name: "Child", href: "/b", icon: "check")
        end
      end
      menu.with_bottom_group(name: "Account", icon: "user") do |group|
        group.with_item(name: "Profile", href: "/b", icon: "user")
      end
    end
  end

  golden("side_menu/custom_icon") do
    with_custom_icons("golden-custom" => '<svg viewBox="0 0 1 1"><rect width="1"/></svg>') do
      side_menu(current_path: "/c", collapsible: true) do |menu|
        menu.with_list do |list|
          list.with_item(name: "Custom", href: "/c", icon: "golden-custom")
          list.with_item(name: "Group", icon: "golden-custom") do |group|
            group.with_item(name: "Child", href: "/c", icon: "golden-custom")
          end
        end
      end
    end
  end

  golden("side_menu/escaping") do
    side_menu(current_path: %(/search?q=a&b="c"), collapsible: true) do |menu|
      menu.with_list(title: %(Tom & Jerry <b>"q"</b>), title_class: %(t"c)) do |list|
        list.with_item(name: %(Tom & Jerry <b>"q"</b> 'x'), href: %(/search?q=a&b="c"<d>), icon: "search",
                       badge: %(<1> & "2"), class: %(c"1 <c2>), data: { turbo_frame: %(<x>"&) }, id: %(i"d))
        list.with_item(name: %(<em>Safe</em>).html_safe, href: %(/safe?x="1"&y=<2>).html_safe)
        list.with_item(name: "Group <&>", href: %(/g?a=1&b=2)) do |group|
          group.with_item(name: %(Child "<&>"), href: %(/search?q=a&b="c"), icon: "check")
        end
        list.with_item(name: "Drop <&>", group_behavior: :dropdown) do |group|
          group.with_item(name: %(Child "<&>"), href: %(/d?x=1&y=2), target: %(_blank))
        end
      end
    end
  end

  golden("side_menu/host_options") do
    side_menu(current_path: "/a", id: "custom-menu", class: "host-nav", data: { controller: "golden", turbo: false },
              aria_label: "Admin <sections>", fixed: false, reveal_current: false) do |menu|
      menu.with_list(class: "host-list", data: { list: "1" }) do |list|
        list.with_item(name: "A", href: "/a", class: "host-item", data: { turbo: false, action: "click->x#y" },
                       id: "item-a", title: "Title & more", "aria-describedby": "d")
        list.with_item(name: "B", href: "/b", class: "host-item")
        list.with_item(name: "Repeated classes", href: "/r", class: "x x  y menu-item")
        list.with_item(name: "Group", class: "host-group", data: { group: "g" }) do |group|
          group.with_item(name: "Child", href: "/a", class: "host-child", data: { child: "c" })
        end
      end
    end
  end

  golden("side_menu/matching") do
    side_menu(current_path: "/items/42/edit.html?tab=1") do |menu|
      menu.with_list do |list|
        list.with_item(name: "Exact", href: "/items/42/edit")
        list.with_item(name: "Exact query", href: "/items/42/edit?tab=2")
        list.with_item(name: "Crud", href: "/items", match: :crud)
        list.with_item(name: "Crud other", href: "/item", match: :crud)
        list.with_item(name: "Starts", href: "/items/4", match: :starts_with)
        list.with_item(name: "Partial", href: "42/ed", match: :partial)
        list.with_item(name: "Unknown match", href: "/items", match: :fuzzy)
        list.with_item(name: "When string", href: "/x", active_when: "/items/")
        list.with_item(name: "When regexp", href: "/x", active_when: %r{/\d+/edit\z})
        list.with_item(name: "When proc", href: "/x", active_when: ->(path) { path.end_with?("edit") })
        list.with_item(name: "When array", href: "/x", active_when: [ "/nope", %r{items} ])
        list.with_item(name: "When miss", href: "/x", active_when: [ "/nope" ])
        list.with_item(name: "Forced on", href: "/elsewhere", active: true)
        list.with_item(name: "Forced off", href: "/items/42/edit", active: false)
        list.with_item(name: "Absolute URL", href: "https://example.com/items/42/edit")
        list.with_item(name: "Bad URI", href: "/items/<42>/edit")
        list.with_item(name: "Group forced", active: false) do |group|
          group.with_item(name: "Child", href: "/items/42/edit")
        end
      end
    end
  end

  golden("side_menu/no_current_path") do
    side_menu(current_path: nil) do |menu|
      menu.with_list { |list| list.with_item(name: "A", href: "/a", icon: "star", active_when: "/a") }
    end
  end

  golden("side_menu/locale_es") do
    I18n.with_locale(:es) do
      side_menu(current_path: "/a", collapsible: true) do |menu|
        menu.with_list do |list|
          list.with_item(name: "Grupo", icon: "folder") { |group| group.with_item(name: "A", href: "/a") }
        end
      end
    end
  end

  golden("command/items") do
    render_html(Bali::Command::Component.new(placeholder: %(Find "<&>"))) do |palette|
      palette.with_group(name: %(Pages <&> "q"), mode: :navigation) do |group|
        group.with_item(title: "Dashboard", meta: "Overview", icon: "layout-dashboard", href: "/dashboard")
        group.with_item(title: "No icon", meta: "Meta", href: "/no-icon")
        group.with_item(title: "No meta", icon: "film", href: "/no-meta")
        group.with_item(title: "No href", icon: "plus")
        group.with_item(title: "Kept", icon: "visa", href: "/kept")
        group.with_item(title: "Mapped", icon: "edit", href: "/mapped")
      end
      palette.with_group(name: "Recent", mode: :recent) do |group|
        group.with_item(title: "Política de Ética", meta: "POL-2026 · Activa", icon: "file-text", href: "/p?a=1&b=2")
        group.with_item(title: "Override", search: "Custom SEARCH Ñandú", href: "/o")
      end
      palette.with_group(name: "Actions", mode: :action) { |group| group.with_item(title: "Act", icon: "zap") }
      palette.with_group(name: "Unknown mode", mode: :fuzzy) { |group| group.with_item(title: "Item", href: "/i") }
    end
  end

  golden("command/escaping") do
    render_html(Bali::Command::Component.new) do |palette|
      palette.with_group(name: "<script>alert(1)</script>") do |group|
        group.with_item(title: %(<script>"t" & 'q'</script>), meta: %(<b>m</b> & "q"),
                        href: %(/s?q="x"&y=<z>), icon: "search")
        group.with_item(title: %(<em>safe</em>).html_safe, meta: %(<i>safe</i>).html_safe,
                        href: %(/safe?x="1").html_safe)
        group.with_item(title: "Search escapes", search: %(<A & "B">))
      end
    end
  end

  golden("command/host_options") do
    render_html(Bali::Command::Component.new) do |palette|
      palette.with_group(name: "Pages", class: "host-group", data: { golden: "g", mode: "overridden" }, id: "g1") do |group|
        group.with_item(title: "Row", href: "/row", icon: "star", class: "host-row is-x",
                        data: { action: "click->other#go", extra: %(<1>) }, id: "row-1", "aria-label": %(Row "1"))
        group.with_item(title: "Data only", href: "/d", data: { href: "/override", search: "custom" })
        group.with_item(title: "Class only", class: "only")
        group.with_item(title: "Nil class", class: nil, href: "/n")
      end
    end
  end

  golden("command/options") do
    [
      render_html(Bali::Command::Component.new(trigger: false, density: :compact, shortcut_label: nil)) do |palette|
        palette.with_group(name: "G") { |group| group.with_item(title: "T", href: "/t", icon: "star") }
      end,
      render_html(Bali::Command::Component.new(shortcut_label: "Ctrl+K", trigger_label: "Go <&>",
                                               no_results_text: "None & \"nada\"", no_results_subtitle: "Try <x>"))
    ].join("\n")
  end

  golden("command/item_values") do
    [
      { title: "Nil mode", mode: nil, href: "/n" },
      { title: "String mode", mode: "navigation", href: "/s" },
      { title: "Symbol href", href: :root },
      { title: "URI href", href: URI("https://example.com/a?b=1&c=2") },
      { title: "Number href", href: 42 },
      { title: 2026, meta: :sym, icon: "star" },
      { title: "Symbol search", search: :Custom }
    ].map { |options| render_html(Bali::Command::Item::Component.new(**options)) }.join("\n")
  end

  golden("command/locale_es") do
    I18n.with_locale(:es) do
      render_html(Bali::Command::Component.new) do |palette|
        palette.with_group(name: "Páginas") { |group| group.with_item(title: "Inicio", href: "/", icon: "house") }
      end
    end
  end

  %i[en es].each do |locale|
    golden("app_layout/fleet_shape-#{locale}") do
      I18n.with_locale(locale) do
        render_html(Bali::AppLayout::Component.new(flash: { notice: "Saved <b>&</b>", alert: %(Fail "x") },
                                                   modal: true, modal_size: :lg, drawer: true, drawer_size: :xl,
                                                   app_name: "Gobierno & Co")) do |layout|
          layout.with_topbar do
            render_html(Bali::Topbar::Component.new) do |topbar|
              topbar.with_search do
                render_html(Bali::Command::Component.new(placeholder: "Buscar…")) do |palette|
                  palette.with_group(name: "Módulos", mode: :navigation) do |group|
                    group.with_item(title: "Órganos", meta: "Gobierno", icon: "landmark", href: "/governing_bodies")
                    group.with_item(title: "Dominios", meta: "Datos", icon: "database", href: "/data_domains")
                  end
                end
              end
              topbar.with_action do
                render_html(Bali::Topbar::IconAction::Component.new(icon: "bell", aria_label: "Avisos <3>"))
              end
            end
          end
          layout.with_sidebar do
            side_menu(current_path: "/data_domains/42/edit", collapsible: true, brand: "GC") do |menu|
              menu.with_list(title: "Datos") do |list|
                list.with_item(name: "Dominios", href: "/data_domains", icon: "database", match: :crud)
                list.with_item(name: "Gobierno", icon: "landmark") do |group|
                  group.with_item(name: "Órganos", href: "/governing_bodies", match: :crud)
                  group.with_item(name: "Sesiones", href: "/sessions", badge: 4)
                end
              end
              menu.with_bottom_item(name: "Ayuda", href: "/help", icon: "circle-help", target: "_blank")
            end
          end
          layout.with_body { "<p>Body</p>".html_safe }
        end
      end
    end
  end

  private

  # Returns the SafeBuffer, so a render nested in a slot block is not escaped again.
  def render_html(component, &block)
    @vc_test_view_context = nil
    vc_test_view_context.render(component, {}, &block)
  end

  def icon(name, **options)
    render_html(Bali::Icon::Component.new(name, **options))
  end

  def side_menu(**options, &block)
    render_html(Bali::SideMenu::Component.new(**options), &block)
  end

  def render_preview_example(preview_class, example, **params)
    args = preview_class.render_args(example, params: params)
    view = vc_test_controller.view_context
    view.lookup_context.prepend_view_paths([ COMPONENTS ])

    if args[:component]
      view.render(args[:component], args[:args], &args[:block])
    else
      view.render(template: args[:template], locals: args[:locals] || {})
    end
  end

  def with_custom_icons(icons)
    previous = Bali.custom_icons
    Bali.custom_icons = previous.merge(icons)
    yield
  ensure
    Bali.custom_icons = previous
  end

  def assert_golden(name, html)
    html = normalize_lucide(html.to_str)
    path = DIR.join("#{name}.html")

    file = path.relative_path_from(Bali::Engine.root)

    if ENV["GOLDEN"] == "update"
      flunk("GOLDEN=update compares each file with itself; it never runs in CI") if ENV["CI"]
      FileUtils.mkdir_p(path.dirname)
      File.write(path, html)
      skip("Wrote #{file}: review its diff")
    end

    assert(path.exist?, "No #{file}: write it with GOLDEN=update and review it")
    assert_equal(File.read(path), html,
                 "#{name} no longer renders #{file}. If the change is deliberate, rewrite it with GOLDEN=update")
  end

  def normalize_lucide(html)
    html.gsub(LUCIDE_SVG) do
      open_tag, body, close_tag = Regexp.last_match.captures
      name = LUCIDE_NAMES[body]
      name ? "#{open_tag}<!-- lucide: #{name} -->#{close_tag}" : "#{open_tag}#{body}#{close_tag}"
    end
  end
end
