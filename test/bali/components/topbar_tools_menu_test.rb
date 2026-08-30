# frozen_string_literal: true

require "test_helper"

# El menú de herramientas internas del topbar.
#
# Recibe herramientas YA FILTRADAS POR PERMISO y se encarga de dos cosas: descartar las que
# no existen en este ambiente (preguntándole a su propio contexto de vista) y pintarlas.
#
# El reparto es deliberado: el host responde "¿quién puede verla?" —lo único que sabe— y el
# componente "¿existe aquí?". Así el host nunca toca rutas y la gema nunca toca permisos.
class BaliTopbarToolsMenuComponentTest < ComponentTestCase
  def montada(**overrides)
    # `rails_health_check_path` existe en el dummy (`/up`), así que sirve como herramienta
    # montada de verdad, resuelta contra el contexto de vista real del render.
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

  # LA prueba del mecanismo: una herramienta cuya ruta no está montada no se ofrece, y si no
  # queda ninguna el menú entero desaparece — un trigger que abre un panel vacío es peor que
  # no tenerlo.
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

  # El corte de la pestaña nueva NO es "montada aquí vs externa": es si conserva el cromo de
  # la app. Una herramienta montada que trae layout propio abre aparte; una que hereda el
  # layout del host, no.
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

  # `:sentry` es ambigua a propósito de la vieja versión de esta prueba: la etiqueta de la
  # gema y `humanize` coinciden ("Sentry"), así que pasaba igual con `label_for` vacío.
  # `:mission_control` distingue de verdad: la gema dice "Jobs dashboard", humanize diría
  # "Mission control".
  def test_a_known_key_uses_the_gems_label
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mission_control) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Jobs dashboard")
  end

  def test_an_unknown_key_falls_back_to_humanize
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mi_herramienta) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Mi herramienta")
  end

  # El override del host vive fuera del namespace de la gema: `topbar.tools_menu.items.<key>`,
  # no `bali_view.topbar.tools_menu.items.<key>`. `label_for` lo mira primero.
  def test_a_host_override_wins_over_the_gems_label
    I18n.backend.store_translations(:en, topbar: { tools_menu: { items: { mission_control: "Panel propio" } } })

    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mission_control) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Panel propio")
  ensure
    I18n.backend.reload!
  end

  # Es un control de sólo ícono: sin nombre accesible no tiene nombre en absoluto.
  # El dummy corre en `en` (spec/dummy/config/application.rb): las etiquetas que se afirman
  # aquí son las inglesas, aunque las dos locales se agreguen juntas.
  def test_the_trigger_has_an_accessible_name
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ]))

    assert_selector('.bali-topbar-tools-menu [aria-label="Tools"]')
  end

  def test_the_accessible_name_can_be_overridden
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ], aria_label: "Utilities"))

    assert_selector('.bali-topbar-tools-menu [aria-label="Utilities"]')
  end

  # Misma cascada que `label_for` para los ítems: clave del host antes que la de la gema.
  def test_the_trigger_label_can_be_overridden_via_i18n
    I18n.backend.store_translations(:en, topbar: { tools_menu: { trigger_label: "Utils" } })

    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ]))

    assert_selector('.bali-topbar-tools-menu [aria-label="Utils"]')
  ensure
    I18n.backend.reload!
  end
end
