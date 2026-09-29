# frozen_string_literal: true

require "test_helper"

# The topbar's internal tools menu.
#
# It receives tools ALREADY FILTERED BY PERMISSION and takes care of two things: discarding the ones
# that do not exist in this environment (by asking its own view context) and painting them.
#
# The split is deliberate: the host answers "who may see it?" —the only thing it knows— and the
# component "does it exist here?". That way the host never touches routes and the gem never touches
# permissions.
class BaliTopbarToolsMenuComponentTest < ComponentTestCase
  def montada(**overrides)
    # `rails_health_check_path` exists in the dummy (`/up`), so it serves as a genuinely mounted
    # tool, resolved against the render's real view context.
    Bali::Topbar::ToolsMenu::Tool.new(
      **{ key: :rails_routes, icon: "route", route_helper: :rails_health_check_path }.merge(overrides)
    )
  end

  def externa(**overrides)
    Bali::Topbar::ToolsMenu::Tool.new(
      **{ key: :repository, icon: "github", url: -> { "https://example.test/repo" } }.merge(overrides)
    )
  end

  def sin_montar
    Bali::Topbar::ToolsMenu::Tool.new(
      key: :letter_opener, icon: "mail-open", route_helper: :helper_que_no_existe_path
    )
  end

  def test_it_does_not_render_without_tools
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: []))

    assert_no_selector(".bali-topbar-tools-menu")
  end

  # THE test of the mechanism: a tool whose route is not mounted is not offered, and if none is left
  # the whole menu disappears — a trigger that opens an empty panel is worse than no trigger.
  def test_it_does_not_render_when_no_tool_is_available
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ sin_montar ]))

    assert_no_selector(".bali-topbar-tools-menu")
  end

  def test_it_drops_the_unavailable_and_keeps_the_available
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ sin_montar, montada ]))

    assert_selector(".bali-topbar-tools-menu")
    assert_selector('.bali-topbar-tools-menu a[href="/up"]')
    assert_no_selector('.bali-topbar-tools-menu a[href^="/letter_opener"]')
  end

  def test_an_external_tool_renders_its_url
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa ]))

    assert_selector('.bali-topbar-tools-menu a[href="https://example.test/repo"]')
  end

  # The cut for a new tab is NOT "mounted here vs external": it is whether it keeps the app's chrome.
  # A mounted tool that brings its own layout opens apart; one that inherits the host's layout does
  # not.
  def test_tools_that_keep_the_host_chrome_open_in_the_same_tab
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada(in_app: true) ]))

    assert_selector('.bali-topbar-tools-menu a[href="/up"]')
    assert_no_selector('.bali-topbar-tools-menu a[target="_blank"]')
  end

  def test_tools_that_bring_their_own_chrome_open_in_a_new_tab
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada, externa ]))

    assert_selector('.bali-topbar-tools-menu a[target="_blank"][rel~="noopener"]', count: 2)
  end

  def test_an_explicit_name_wins_over_i18n
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada(name: "Mi etiqueta") ]))

    assert_selector(".bali-topbar-tools-menu", text: "Mi etiqueta")
  end

  # `:sentry` is ambiguous, which is what was wrong with the old version of this test: the gem's
  # label and `humanize` coincide ("Sentry"), so it passed just as well with `label_for` empty.
  # `:mission_control` really tells them apart: the gem says "Jobs dashboard", humanize would say
  # "Mission control".
  def test_a_known_key_uses_the_gems_label
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mission_control) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Jobs dashboard")
  end

  # `:flightdeck` is the jobs dashboard of the apps that swapped mission_control-jobs for
  # solid_queue-flightdeck (#1138). It tells them apart the same way `:mission_control` does: the gem
  # says "Jobs dashboard" and humanize would say "Flightdeck". `:mission_control` stays —afal-apps is
  # still on that gem— so both keys coexist under the same label.
  def test_the_flightdeck_key_uses_the_gems_label
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :flightdeck) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Jobs dashboard")
  end

  def test_an_unknown_key_falls_back_to_humanize
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mi_herramienta) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Mi herramienta")
  end

  # The host's override lives outside the gem's namespace: `topbar.tools_menu.items.<key>`, not
  # `bali_view.topbar.tools_menu.items.<key>`. `label_for` looks there first.
  def test_a_host_override_wins_over_the_gems_label
    I18n.backend.store_translations(:en, topbar: { tools_menu: { items: { mission_control: "Panel propio" } } })

    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mission_control) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Panel propio")
  ensure
    I18n.backend.reload!
  end

  # It is an icon-only control: with no accessible name it has no name at all.
  # The dummy runs in `en` (test/dummy/config/application.rb): the labels asserted here are the
  # English ones, even though both locales are added together.
  def test_the_trigger_has_an_accessible_name
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ]))

    assert_selector('.bali-topbar-tools-menu [aria-label="Tools"]')
  end

  def test_the_accessible_name_can_be_overridden
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ], aria_label: "Utilities"))

    assert_selector('.bali-topbar-tools-menu [aria-label="Utilities"]')
  end

  # Same cascade as `label_for` for the items: the host's key before the gem's.
  def test_the_trigger_label_can_be_overridden_via_i18n
    I18n.backend.store_translations(:en, topbar: { tools_menu: { trigger_label: "Utils" } })

    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ]))

    assert_selector('.bali-topbar-tools-menu [aria-label="Utils"]')
  ensure
    I18n.backend.reload!
  end
end
