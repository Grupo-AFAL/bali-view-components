# Bali::Topbar::ToolsMenu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extraer a Bali el menú de herramientas internas del topbar, que hoy vive duplicado
en cuatro apps, y publicarlo en **v3.2.0**.

**Architecture:** Dos objetos. `Tool` es un `Data` que responde "¿existe esta herramienta en
este ambiente?" preguntándole a un contexto que **recibe** (nunca a `Rails.application`).
`Component` es un `Bali::Dropdown` que recibe herramientas **ya filtradas por permiso**,
descarta las no disponibles contra su propio contexto de vista, y pinta el resto. La gema
nunca evalúa permisos; el host nunca toca rutas.

**Tech Stack:** Ruby 4.0.1 (vía `mise`), Rails 8.1, ViewComponent, Minitest + Capybara
(`ComponentTestCase`), Lookbook para previews.

**Spec:** `docs/superpowers/specs/2026-08-29-topbar-tools-menu-design.md`

**Alcance:** este plan cubre **sólo la gema**, hasta el tag `v3.2.0`. La migración de las
cuatro apps (gobierno-corporativo, opina, afal-apps, identity) necesita una versión
publicada para empezar, así que lleva su propio plan — ver "Después de este plan".

## Global Constraints

- **Ruby siempre por `mise`**: los shims no resuelven solos. Todo comando va como
  `mise x ruby@4.0.1 -- <cmd>`.
- **El `git push` también**: `.githooks/pre-push` corre la suite completa y necesita
  `bundle` en el PATH. Empujar con `mise x ruby@4.0.1 -- git push`.
- **Antes de la primera corrida, compilar los assets del dummy** o la suite tira ~50 fallas
  fantasma de `The asset 'tailwind.css' was not found in the load path` (ver Task 0).
- **Versión objetivo: `3.2.0`** en `lib/bali/version.rb` (hoy `3.1.5`). API nueva, sin
  cambios incompatibles.
- **Namespace**: `Bali::Topbar::ToolsMenu`. Clase CSS raíz: `bali-topbar-tools-menu`.
- **Claves i18n**: `bali_view.topbar.tools_menu.*` en `config/locales/bali_view.es.yml` **y**
  `bali_view.en.yml`. Las dos se tocan siempre juntas.
- **Las seis claves conocidas** son exactamente: `mission_control`, `analytics`,
  `letter_opener`, `rails_routes`, `repository`, `sentry`.
- **CHANGELOG**: toda entrada va bajo `## [Unreleased]` con su categoría Keep-a-Changelog.

---

### Task 0: Preparar el worktree

**Files:** ninguno (setup del entorno).

**Interfaces:**
- Consumes: nada.
- Produces: una suite que corre en verde, que es la línea base contra la que se compara todo
  lo demás.

- [ ] **Step 1: Instalar dependencias de node de la gema y del dummy**

```bash
cd <worktree>
mise x ruby@4.0.1 -- yarn install
cd spec/dummy && mise x ruby@4.0.1 -- yarn install
```

- [ ] **Step 2: Compilar los assets del dummy**

```bash
cd spec/dummy
mise x ruby@4.0.1 -- yarn build
mise x ruby@4.0.1 -- bin/rails tailwindcss:build
```

- [ ] **Step 3: Correr la suite completa como línea base**

Run: `cd <worktree> && mise x ruby@4.0.1 -- bin/rails test`
Expected: PASS — `4871 runs, 0 failures, 0 errors, 0 skips` (el número de runs puede subir
si `main` avanzó; lo que importa es **0 failures y 0 errors**).

Si hay fallas de `The asset 'tailwind.css' was not found`, los pasos 1–2 no se completaron.

---

### Task 1: `Tool` — el objeto y la regla del router

**Files:**
- Create: `app/components/bali/topbar/tools_menu/tool.rb`
- Test: `test/bali/components/topbar_tools_menu_tool_test.rb`

**Interfaces:**
- Consumes: nada.
- Produces: `Bali::Topbar::ToolsMenu::Tool`, un `Data` con miembros
  `(key, icon, route_helper, url, in_app, name, meta)` y los métodos
  `#available?(context) -> Boolean`, `#href(context) -> String`, `#in_app? -> Boolean`,
  `#new_tab? -> Boolean`. `Task 2` lo consume.

- [ ] **Step 1: Escribir las pruebas que fallan**

Create `test/bali/components/topbar_tools_menu_tool_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"

# `Tool` responde dos preguntas: "¿existe esta herramienta en este ambiente?" y "¿a dónde
# apunta?". La primera la contesta preguntándole a un CONTEXTO QUE RECIBE — nunca a
# `Rails.application.routes.url_helpers`. Por eso estas pruebas usan un doble y no montan
# rutas: es la ventaja concreta de recibir el contexto en vez de buscarlo.
class BaliTopbarToolsMenuToolTest < ComponentTestCase
  # Un contexto de vista de mentiras: responde sólo a los helpers que se le declaran.
  class FakeContext
    def initialize(rutas = {})
      @rutas = rutas
    end

    def respond_to?(name, include_all = false)
      @rutas.key?(name) || super
    end

    def public_send(name, *args)
      @rutas.key?(name) ? @rutas[name] : super
    end
  end

  def tool(**overrides)
    Bali::Topbar::ToolsMenu::Tool.new(
      **{ key: :letter_opener, icon: "mail-open", route_helper: :letter_opener_web_path }.merge(overrides)
    )
  end

  def test_a_mounted_tool_is_available_when_the_context_knows_its_helper
    context = FakeContext.new(letter_opener_web_path: "/letter_opener")

    assert tool.available?(context)
    assert_equal "/letter_opener", tool.href(context)
  end

  def test_a_mounted_tool_is_not_available_when_the_context_does_not_know_its_helper
    assert_not tool.available?(FakeContext.new)
  end

  def test_an_external_tool_is_available_when_its_url_resolves
    external = tool(key: :repository, route_helper: nil, url: -> { "https://example.test/repo" })

    assert external.available?(FakeContext.new)
    assert_equal "https://example.test/repo", external.href(FakeContext.new)
  end

  def test_an_external_tool_whose_url_resolves_to_nil_is_not_available
    external = tool(key: :sentry, route_helper: nil, url: -> {})

    assert_not external.available?(FakeContext.new)
  end

  def test_the_url_is_re_read_on_every_call
    valor = "https://first.test"
    external = tool(key: :sentry, route_helper: nil, url: -> { valor })

    assert_equal "https://first.test", external.href(FakeContext.new)
    valor = "https://second.test"
    assert_equal "https://second.test", external.href(FakeContext.new)
  end

  def test_new_tab_is_the_inverse_of_in_app
    assert_predicate tool, :new_tab?
    assert_not_predicate tool, :in_app?

    dentro = tool(in_app: true)
    assert_predicate dentro, :in_app?
    assert_not_predicate dentro, :new_tab?
  end

  def test_route_helper_and_url_together_raise
    error = assert_raises(ArgumentError) do
      Bali::Topbar::ToolsMenu::Tool.new(
        key: :x, icon: "wrench", route_helper: :some_path, url: -> { "https://example.test" }
      )
    end

    assert_includes error.message, "exclusive"
  end

  def test_neither_route_helper_nor_url_raises
    error = assert_raises(ArgumentError) do
      Bali::Topbar::ToolsMenu::Tool.new(key: :x, icon: "wrench")
    end

    assert_includes error.message, "route_helper"
  end

  # `meta` es del host: la gema lo transporta y nunca lo interpreta.
  def test_meta_round_trips_untouched
    con_meta = tool(meta: { gate: "system.admin" })

    assert_equal({ gate: "system.admin" }, con_meta.meta)
  end

  def test_meta_defaults_to_an_empty_hash
    assert_empty tool.meta
  end
end
```

- [ ] **Step 2: Correr la prueba para verificar que falla**

Run: `mise x ruby@4.0.1 -- bin/rails test test/bali/components/topbar_tools_menu_tool_test.rb`
Expected: FAIL con `NameError: uninitialized constant Bali::Topbar::ToolsMenu`

- [ ] **Step 3: Escribir la implementación mínima**

Create `app/components/bali/topbar/tools_menu/tool.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Topbar
    module ToolsMenu
      # Una herramienta del menú del topbar.
      #
      # Responde dos preguntas y ninguna más: "¿existe en este ambiente?" y "¿a dónde
      # apunta?". Quién la puede ver NO es asunto suyo — eso lo decide el host, que pasa la
      # lista ya filtrada (ver el spec: es lo que permite que apps con modelos de
      # autorización distintos usen el mismo componente).
      #
      # El `context` se RECIBE, no se busca. Es el contexto de vista donde el componente ya
      # se está renderizando, no `Rails.application.routes.url_helpers`. Además de evitar
      # el estado global, el contexto de vista resuelve los proxies de engine
      # (`main_app.`, etc.) que el objeto global NO incluye.
      Tool = Data.define(:key, :icon, :route_helper, :url, :in_app, :name, :meta) do
        def initialize(key:, icon:, route_helper: nil, url: nil, in_app: false, name: nil, meta: {})
          if route_helper && url
            raise ArgumentError,
                  "`route_helper:` and `url:` are exclusive: a tool is either mounted in the " \
                  "host app (route_helper) or lives elsewhere (url)."
          end

          if route_helper.nil? && url.nil?
            raise ArgumentError,
                  "a tool needs `route_helper:` (mounted in the host app) or `url:` (a lambda " \
                  "returning an external URL)."
          end

          super
        end

        # `route_helper` presente: existe si el contexto conoce ese helper — así es como una
        # herramienta se enciende sola en cuanto su ruta se monta, sin copiar aquí la
        # condición de ambiente del host.
        #
        # OJO con lo que esto NO cubre: un `constraints` en la ruta no impide que el helper
        # exista. La pregunta es "¿está montada?", no "¿este usuario pasa?".
        def available?(context)
          route_helper ? context.respond_to?(route_helper) : href(context).present?
        end

        def href(context)
          route_helper ? context.public_send(route_helper) : url.call
        end

        def in_app? = in_app

        def new_tab? = !in_app?
      end
    end
  end
end
```

- [ ] **Step 4: Correr la prueba para verificar que pasa**

Run: `mise x ruby@4.0.1 -- bin/rails test test/bali/components/topbar_tools_menu_tool_test.rb`
Expected: PASS — `10 runs, 0 failures, 0 errors`

- [ ] **Step 5: Commit**

```bash
git add app/components/bali/topbar/tools_menu/tool.rb test/bali/components/topbar_tools_menu_tool_test.rb
git commit -m "feat(topbar): Tool, la regla del router del menú de herramientas"
```

---

### Task 2: `Component` — el dropdown

**Files:**
- Create: `app/components/bali/topbar/tools_menu/component.rb`
- Create: `app/components/bali/topbar/tools_menu/component.html.erb`
- Test: `test/bali/components/topbar_tools_menu_test.rb`

**Interfaces:**
- Consumes: `Bali::Topbar::ToolsMenu::Tool` de Task 1 (`#available?(context)`,
  `#href(context)`, `#new_tab?`, `#icon`, `#key`, `#name`).
- Produces: `Bali::Topbar::ToolsMenu::Component.new(tools:, icon:, aria_label:, align:,
  **options)`. Task 3 le agrega el preview.

- [ ] **Step 1: Escribir las pruebas que fallan**

Create `test/bali/components/topbar_tools_menu_test.rb`:

```ruby
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

  def test_a_known_key_uses_the_gems_label
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :sentry) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Sentry")
  end

  def test_an_unknown_key_falls_back_to_humanize
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ externa(key: :mi_herramienta) ]))

    assert_selector(".bali-topbar-tools-menu", text: "Mi herramienta")
  end

  # Es un control de sólo ícono: sin nombre accesible no tiene nombre en absoluto.
  def test_the_trigger_has_an_accessible_name
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ]))

    assert_selector('.bali-topbar-tools-menu [aria-label="Herramientas"]')
  end

  def test_the_accessible_name_can_be_overridden
    render_inline(Bali::Topbar::ToolsMenu::Component.new(tools: [ montada ], aria_label: "Utilidades"))

    assert_selector('.bali-topbar-tools-menu [aria-label="Utilidades"]')
  end
end
```

- [ ] **Step 2: Correr la prueba para verificar que falla**

Run: `mise x ruby@4.0.1 -- bin/rails test test/bali/components/topbar_tools_menu_test.rb`
Expected: FAIL con `NameError: uninitialized constant Bali::Topbar::ToolsMenu::Component`

- [ ] **Step 3: Escribir la implementación mínima**

Create `app/components/bali/topbar/tools_menu/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Topbar
    module ToolsMenu
      # El menú de herramientas internas del topbar: panel de trabajos, tableros, bandeja de
      # correo, repositorio, monitoreo. Va en el slot `with_action` de `Bali::Topbar`.
      #
      # Recibe las herramientas YA FILTRADAS POR PERMISO. La gema no evalúa permisos: los
      # hosts que la usan no comparten vocabulario de autorización (unos tienen permisos con
      # nombre, otros policies), y dejar esa decisión afuera es lo que permite que el mismo
      # componente les sirva a todos sin casos especiales.
      #
      # Lo que sí decide el componente es qué existe en ESTE ambiente, preguntándole a su
      # propio contexto de vista (ver `Tool#available?`). Si no queda ninguna, no se
      # renderiza: un trigger que abre un panel vacío es peor que no tenerlo.
      class Component < ApplicationViewComponent
        # @param tools [Array<Tool>] ya filtradas por permiso.
        # @param icon [String] ícono del trigger.
        # @param aria_label [String, nil] nombre accesible del trigger; por default el
        #   traducido. Es de sólo ícono: sin nombre accesible no tiene nombre.
        # @param align [Symbol] eje horizontal del dropdown.
        def initialize(tools:, icon: "wrench", aria_label: nil, align: :end, **options)
          @tools = Array(tools)
          @icon = icon
          @aria_label = aria_label
          @align = align
          @options = options
        end

        def render?
          visible_tools.any?
        end

        # `helpers` es el contexto de vista del render en curso: el colaborador que ya
        # tenemos, en vez de alcanzar `Rails.application`.
        def visible_tools
          @visible_tools ||= @tools.select { |tool| tool.available?(helpers) }
        end

        def href_for(tool)
          tool.href(helpers)
        end

        # `name:` explícito → clave del host → clave de la gema → humanize.
        def label_for(tool)
          return tool.name if tool.name.present?

          t("topbar.tools_menu.items.#{tool.key}",
            default: [ :"bali_view.topbar.tools_menu.items.#{tool.key}", tool.key.to_s.humanize ])
        end

        def trigger_label
          @aria_label || t("bali_view.topbar.tools_menu.trigger_label")
        end

        def link_options(tool)
          return {} unless tool.new_tab?

          { target: "_blank", rel: "noopener" }
        end

        def dropdown_options
          @options.merge(
            align: @align,
            class: class_names("bali-topbar-tools-menu", @options[:class])
          )
        end

        attr_reader :icon
      end
    end
  end
end
```

Create `app/components/bali/topbar/tools_menu/component.html.erb`:

```erb
<%= render Bali::Dropdown::Component.new(**dropdown_options) do |dropdown| %>
  <% dropdown.with_trigger(variant: :icon, title: trigger_label, "aria-label": trigger_label) do %>
    <%= render Bali::Icon::Component.new(icon, size: :small) %>
  <% end %>

  <% visible_tools.each do |tool| %>
    <% dropdown.with_item(
         href: href_for(tool),
         name: label_for(tool),
         icon: tool.icon,
         **link_options(tool)
       ) %>
  <% end %>
<% end %>
```

- [ ] **Step 4: Correr la prueba para verificar que pasa**

Run: `mise x ruby@4.0.1 -- bin/rails test test/bali/components/topbar_tools_menu_test.rb`
Expected: los casos de etiquetas y de `aria-label` FALLAN todavía — las claves i18n no
existen (Task 3). El resto PASA. Anotar cuáles fallan y seguir; Task 3 los cierra.

- [ ] **Step 5: Commit**

```bash
git add app/components/bali/topbar/tools_menu/ test/bali/components/topbar_tools_menu_test.rb
git commit -m "feat(topbar): componente del menú de herramientas internas"
```

---

### Task 3: i18n y preview

**Files:**
- Modify: `config/locales/bali_view.es.yml`
- Modify: `config/locales/bali_view.en.yml`
- Modify: `app/components/bali/topbar/preview.rb`
- Create: `app/components/bali/topbar/previews/tools_menu.html.erb`
- Test: `test/bali/components/topbar_tools_menu_test.rb` (ya existe, de Task 2)

**Interfaces:**
- Consumes: `Component` de Task 2.
- Produces: las claves `bali_view.topbar.tools_menu.trigger_label` y
  `bali_view.topbar.tools_menu.items.{mission_control,analytics,letter_opener,rails_routes,repository,sentry}`
  en **es** y **en**; y el preview `tools_menu` de Lookbook.

- [ ] **Step 1: Agregar las claves en español**

En `config/locales/bali_view.es.yml`, dentro de `topbar:` (que ya existe con `user_menu:`),
agregar como hermano de `user_menu:`:

```yaml
      tools_menu:
        trigger_label: "Herramientas"
        items:
          mission_control: "Panel de trabajos"
          analytics: "Tablero de adopción"
          letter_opener: "Bandeja de correo"
          rails_routes: "Rutas de Rails"
          repository: "Repositorio"
          sentry: "Sentry"
```

- [ ] **Step 2: Agregar las mismas claves en inglés**

En `config/locales/bali_view.en.yml`, en la misma posición dentro de `topbar:`:

```yaml
      tools_menu:
        trigger_label: "Tools"
        items:
          mission_control: "Jobs dashboard"
          analytics: "Adoption dashboard"
          letter_opener: "Captured email"
          rails_routes: "Rails routes"
          repository: "Repository"
          sentry: "Sentry"
```

- [ ] **Step 3: Correr las pruebas del componente para verificar que ahora pasan todas**

Run: `mise x ruby@4.0.1 -- bin/rails test test/bali/components/topbar_tools_menu_test.rb`
Expected: PASS — `12 runs, 0 failures, 0 errors`

- [ ] **Step 4: Agregar el preview**

En `app/components/bali/topbar/preview.rb`, agregar el método:

```ruby
      # @label Tools Menu
      # Topbar with the internal tools menu: a mounted tool that keeps the host chrome
      # (same tab), a mounted tool with its own chrome, and an external link.
      def tools_menu
        render_with_template(template: "bali/topbar/previews/tools_menu")
      end
```

Create `app/components/bali/topbar/previews/tools_menu.html.erb`:

```erb
<%= render Bali::Topbar::Component.new do |topbar| %>
  <% topbar.with_action do %>
    <%= render Bali::Topbar::ToolsMenu::Component.new(tools: [
      Bali::Topbar::ToolsMenu::Tool.new(
        key: :analytics, icon: "chart-line",
        route_helper: :rails_health_check_path, in_app: true
      ),
      Bali::Topbar::ToolsMenu::Tool.new(
        key: :rails_routes, icon: "route",
        route_helper: :rails_health_check_path
      ),
      Bali::Topbar::ToolsMenu::Tool.new(
        key: :repository, icon: "github",
        url: -> { "https://github.com/Grupo-AFAL/bali-view-components" }
      )
    ]) %>
  <% end %>
<% end %>
```

- [ ] **Step 5: Registrar el preview en su prueba de request**

`test/requests/topbar_previews_test.rb` enumera los previews del Topbar y pide cada uno por
HTTP — es el único camino donde un template de preview roto se manifiesta (#1035). Agregar
`tools_menu` a la constante `PREVIEWS`:

```ruby
  PREVIEWS = %w[
    default
    search_only
    without_search
    without_mobile_trigger
    user_menu
    icon_actions
    tools_menu
  ].freeze
```

- [ ] **Step 6: Verificar que el preview renderiza**

Run: `mise x ruby@4.0.1 -- bin/rails test test/requests/topbar_previews_test.rb`
Expected: PASS — `1 runs, 0 failures, 0 errors` (el test recorre los siete previews).

- [ ] **Step 7: Correr la suite completa**

Run: `mise x ruby@4.0.1 -- bin/rails test`
Expected: PASS — 0 failures, 0 errors.

- [ ] **Step 8: Commit**

```bash
git add config/locales/bali_view.es.yml config/locales/bali_view.en.yml \
        app/components/bali/topbar/preview.rb app/components/bali/topbar/previews/tools_menu.html.erb \
        test/requests/topbar_previews_test.rb
git commit -m "feat(topbar): etiquetas y preview del menú de herramientas"
```

---

### Task 4: CHANGELOG y release v3.2.0

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `lib/bali/version.rb`

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: el tag `v3.2.0`, que es lo que las cuatro apps van a pinear en el plan de
  migración.

- [ ] **Step 1: Agregar la entrada al CHANGELOG**

En `CHANGELOG.md`, bajo `## [Unreleased]`, agregar una sección `### Added` (o sumar a la
existente):

```markdown
- **`Bali::Topbar::ToolsMenu` — el menú de herramientas internas del topbar deja de estar
  duplicado en cada app.** Panel de trabajos, tableros, bandeja de correo, repositorio,
  monitoreo: cuatro apps del grupo lo construyeron por separado y convergieron por su cuenta
  en el mismo mecanismo (dos de ellas byte-idénticas). El componente recibe herramientas
  **ya filtradas por permiso** y resuelve dos cosas: cuáles existen en este ambiente y cómo
  se pintan. **La gema no evalúa permisos** — los hosts no comparten vocabulario de
  autorización (unos usan permisos con nombre, otros policies de Pundit), y dejar esa
  decisión afuera es lo que permite que el mismo componente les sirva a todos sin casos
  especiales. La disponibilidad la decide el ROUTER: cada `Tool` declara el NOMBRE de su
  route helper y se pregunta si el contexto lo conoce, así que el menú **no puede ofrecer un
  enlace que la app no responda** y una herramienta se enciende sola en cuanto su ruta se
  monta — sin copiar la condición de ambiente del host, que es una duplicación que ya costó
  caro (una bandeja de correo servida públicamente en producción). **El contexto se recibe,
  no se busca**: se le pregunta al contexto de vista del render, no a
  `Rails.application.routes.url_helpers` — además de evitar el estado global, eso resuelve
  los proxies de engine (`main_app.`) que el objeto global no incluye. Cada ítem abre en
  pestaña nueva **salvo** los `in_app:`, que son los que conservan el cromo del host:
  mandarlos aparte dejaría la misma app abierta dos veces. Las etiquetas de las seis claves
  conocidas vienen en la gema (es/en), con override del host y `name:` por herramienta.
  Diseño: `docs/superpowers/specs/2026-08-29-topbar-tools-menu-design.md`.
```

- [ ] **Step 2: Subir la versión**

En `lib/bali/version.rb`, cambiar `VERSION = "3.1.5"` por `VERSION = "3.2.0"`.

- [ ] **Step 3: Correr la suite completa una última vez**

Run: `mise x ruby@4.0.1 -- bin/rails test`
Expected: PASS — 0 failures, 0 errors.

- [ ] **Step 4: Commit y push**

```bash
git add CHANGELOG.md lib/bali/version.rb
git commit -m "release: v3.2.0"
mise x ruby@4.0.1 -- git push
```

- [ ] **Step 5: Abrir el PR**

Escribir el cuerpo a un archivo y pasarlo con `--body-file`. Contenido:

```markdown
Extrae a Bali el menú de herramientas internas del topbar, que hoy vive duplicado en cuatro
apps del grupo. Diseño aprobado en `docs/superpowers/specs/2026-08-29-topbar-tools-menu-design.md`.

## Por qué ahora

Las cuatro apps lo construyeron por separado y **convergieron por su cuenta** en el mismo
mecanismo: los de gobierno-corporativo y opina son byte-idénticos (24 líneas), y los de
afal-apps e identity son subconjuntos del mismo código. Ninguna se escribió mirando a las
otras. Esa convergencia es la señal de que la abstracción existe y está madura.

## Las dos decisiones de diseño

**La gema no evalúa permisos.** Recibe herramientas ya filtradas. Los hosts no comparten
vocabulario de autorización —tres usan permisos con nombre, identity usa policies de Pundit
y no tiene `can?`—, así que dejar esa decisión afuera es lo que permite que el mismo
componente les sirva a todos sin casos especiales.

**El contexto de rutas se recibe, no se busca.** `Tool#available?(context)` le pregunta al
contexto de vista del render, no a `Rails.application.routes.url_helpers`. Además de evitar
el estado global, resuelve los proxies de engine (`main_app.`) que el objeto global **no**
incluye — es menos acoplamiento y más capacidad.

## Lo que hace el componente

Decide **qué existe en este ambiente** preguntándole al router (cada `Tool` declara el
NOMBRE de su route helper), y **cómo se pinta**. Así el menú no puede ofrecer un enlace que
la app no responda, y una herramienta se enciende sola en cuanto su ruta se monta — sin
copiar la condición de ambiente del host, duplicación que ya costó una bandeja de correo
servida públicamente en producción.

Cada ítem abre en pestaña nueva **salvo** los `in_app:`, que son los que conservan el cromo
del host: mandarlos aparte dejaría la misma app abierta dos veces.

Límite conocido y documentado en la API: un `constraints` no impide que el route helper
exista, así que la compuerta responde «¿está montada?», no «¿este usuario pasa?».

## Verificación

`bin/rails test` → 0 failures, 0 errors.
```

**No** lleva `Closes #NNN` salvo que exista un issue que cerrar.

- [ ] **Step 6: PARAR — el tag lo corta una persona**

Después del merge, alguien tiene que cortar el tag `v3.2.0`. **Ese paso no es del agente**:
las cuatro apps pinean por tag, y un tag mal cortado las rompe a todas a la vez.

---

## Después de este plan

La migración de las cuatro apps necesita `v3.2.0` publicada, así que va en un plan aparte.
Orden recomendado por el spec, y el porqué:

1. **gobierno-corporativo** — tiene las seis herramientas, las dos ramas de `in_app` y la
   suite más grande (10 730 pruebas). Es la que más rápido expone un hueco en la API.
2. **opina** — cinco herramientas, incluida una `in_app`.
3. **afal-apps** — cinco herramientas, ninguna `in_app`; necesita además el campo `in_app`
   documentado en la nota de su catálogo.
4. **identity** — al final: carga además el salto **v3.1.0 → v3.2.0**, con riesgo propio
   ajeno a este cambio, y es el proveedor de identidad.

En cada app la migración es: pinear la versión, reemplazar `InternalTools::Tool` por el de
la gema, dejar `visible_for` **sólo con el filtro de permiso** (la disponibilidad pasa a
resolverla el componente), y cambiar la clase del selector en sus pruebas de
`.internal-tools-menu` a `.bali-topbar-tools-menu`. Las pruebas de HTML servido de cada app
**se conservan**: son la red que protege que la migración no cambie comportamiento.
