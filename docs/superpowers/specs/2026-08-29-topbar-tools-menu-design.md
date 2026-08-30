# Bali::Topbar::ToolsMenu — Design

Date: 2026-08-29
Status: Approved (brainstorming) — 2026-08-29

## Purpose

El menú de herramientas internas del topbar —panel de trabajos, tablero de adopción,
bandeja de correo, rutas de Rails, repositorio, Sentry— se construyó por separado en cuatro
apps entre el 29/08 y el 30/08 (afal-apps #560, gobierno-corporativo #1005/#1006,
identity #272, opina #67). Las cuatro implementaciones convergieron **por su cuenta** en el
mismo mecanismo. Este documento propone extraerlo a Bali para que dejen de ser cuatro
copias.

El componente es **agnóstico del dominio**: no sabe quién es el usuario ni qué permisos
tiene. Recibe una lista ya filtrada por permiso, descarta lo que no existe en este ambiente
—preguntándole al contexto de vista en el que ya se está renderizando— y pinta el resto.

### La evidencia que justifica la extracción

Medido con `diff` sobre el código real, normalizando sangría y comentarios:

| Pieza | Estado |
|---|---|
| Mecanismo (`Tool`, `available?`, `href`, `new_tab?`) | **Byte-idéntico** entre gobierno-corporativo y opina (24 líneas). afal-apps (18) e identity (15) son **subconjuntos del mismo código** — les faltan los campos que todavía no necesitan |
| Bloque de la vista (el dropdown) | **Idéntico en las cuatro** salvo el prefijo de i18n de identity |
| Helper | Idéntico salvo el predicado de sesión y, en identity, la compuerta |

Son ~36 líneas repetidas cuatro veces frente a 8–14 líneas por app de lo que sí es propio
(catálogo, constantes y gates). La convergencia no fue planeada: cada app se escribió
mirando el problema, no las otras, y llegaron al mismo lugar. Eso es la señal de que la
abstracción existe y está madura.

### Goals

- **Una sola copia de la regla que más importa**: la disponibilidad de una herramienta la
  decide el ROUTER, no una copia de la condición de ambiente de `config/routes.rb`. Esa
  regla existe porque gobierno-corporativo pagó por duplicarla — su bandeja de correo quedó
  servida públicamente en producción (#967) porque la guarda leía `.present?` sobre el `"0"`
  que manda el despliegue. Hoy esa regla vive en cuatro archivos.
- **Una sola copia del criterio de la pestaña nueva**, que ya se trazó mal una vez: no es
  "montada en esta app vs externa", es **si conserva el cromo de la app**.
- Que sumar una herramienta en cualquier app sea una línea declarativa.
- Que las etiquetas sean las mismas en las cuatro apps sin copiarlas.

### Non-goals (YAGNI)

- **La gema NO decide quién ve qué.** Ver "La costura", abajo: es la decisión de diseño
  central y lo que hace viable incluir a identity sin casos especiales.
- No se mueve a la gema el catálogo, ni las constantes de URL, ni los gates. Eso es
  identidad y política de cada app, no código compartido.
- Sin registro global ni configuración de inicializador. El host pasa su lista en el render.
- No se toca el resto del topbar (`IconAction`, `UserMenu`, el slot `search`).

## La costura: la gema no evalúa permisos

Es la decisión que gobierna todo lo demás, y la que resuelve el único caso realmente
divergente.

Tres de las cuatro apps autorizan con permisos con nombre (`user.can?("system.admin")`).
**identity no**: sus roles son constantes (`employee` / `manager` / `admin`) y la
autorización va por policies de Pundit; no existe `Account#can?`. Si la gema evaluara
permisos, identity necesitaría un caso especial dentro de la gema, o quedaría fuera.

Al dejar la autorización del lado del host, esa divergencia **deja de existir para la
gema**: recibe una lista ya filtrada y no le importa cómo se filtró. La gema responde
"¿esta herramienta existe en este ambiente y cómo se pinta?"; el host responde "¿esta
persona la puede ver?".

## Public API

### `Bali::Topbar::ToolsMenu::Tool`

```ruby
Bali::Topbar::ToolsMenu::Tool.new(
  key: :mission_control,          # símbolo; elige la etiqueta por defecto
  icon: "server-cog",             # nombre de ícono (pipeline de Bali::Icon)
  route_helper: :mission_control_jobs_path,  # herramienta montada en la app host
  url: nil,                       # o un lambda, para un enlace externo (excluyente)
  in_app: false,                  # true = conserva el cromo del host
  name: nil,                      # etiqueta explícita; anula la de i18n
  meta: {}                        # libre para el host; la gema NUNCA lo lee
)
```

- `#available?(context)` — `route_helper` presente: `context.respond_to?(route_helper)`.
  Si no: la `url` resuelve a algo no vacío.
- `#href(context)` — `context.public_send(route_helper)`, o llama al lambda.
- `#in_app?` / `#new_tab?` — `new_tab?` es `!in_app?`.

**El `context` se recibe, no se busca.** Es el contexto de vista donde el componente ya se
está renderizando (`helpers`), no `Rails.application.routes.url_helpers`. Tres razones, y la
tercera no es cosmética:

1. La gema deja de alcanzar estado global; usa el colaborador que le dieron.
2. Se prueba con un doble, sin montar rutas.
3. **`Rails.application.routes.url_helpers` NO incluye los proxies de engine**
   (`main_app.`, `bali_auth_admin.`), así que la implementación actual de las cuatro apps no
   puede expresar una herramienta que viva detrás de uno. El contexto de vista sí. Es menos
   acoplamiento **y** más capacidad.

Verificado en gobierno-corporativo: sobre `@controller.view_context`,
`respond_to?(:letter_opener_web_path)` → `true`, `respond_to?(:ruta_inexistente_path)` →
`false`, y `letter_opener_web_path` → `/letter_opener`.

`route_helper` y `url` son **excluyentes**; pasar ambos levanta `ArgumentError` (hoy ninguna
de las cuatro copias lo valida — es una mejora que la extracción compra).

**`url` es un lambda y no un String a propósito**: se relee en cada request en vez de
congelarse al cargar la constante del host.

### `Bali::Topbar::ToolsMenu::Component`

```erb
<% topbar.with_action do %>
  <%= render Bali::Topbar::ToolsMenu::Component.new(tools: visible_internal_tools) %>
<% end %>
```

- `tools:` — array de `Tool`, **filtrado por permiso y nada más**. El componente descarta
  los que no estén `available?` **contra su propio contexto de vista**, y **no se renderiza**
  (`render?` → false) si no queda ninguno: un trigger que abre un panel vacío es peor que no
  tenerlo.
- `icon:` (default `"wrench"`), `aria_label:` (default traducido), `align:` (default `:end`).
- Emite la clase `bali-topbar-tools-menu` en la raíz, para que los hosts puedan afirmarla en
  sus pruebas (las cuatro apps ya lo hacen con `.internal-tools-menu`).

Cada ítem lleva `target="_blank" rel="noopener"` **salvo** los `in_app?`.

**El reparto del filtrado es deliberado**, y es lo que mantiene bajo el acoplamiento:

| Pregunta | Quién la responde | Por qué |
|---|---|---|
| ¿Quién puede verla? | **El host** | Es lo único que sabe: permisos con nombre en tres apps, una policy de Pundit en identity |
| ¿Existe en este ambiente? | **El componente** | Ya tiene el contexto de vista; el host no necesita uno para armar su lista |

Así el host nunca toca rutas y la gema nunca toca permisos.

### i18n

La gema trae las etiquetas de las claves conocidas en
`bali_view.topbar.tools_menu.items.*` — `mission_control`, `analytics`, `letter_opener`,
`rails_routes`, `repository`, `sentry` — más `bali_view.topbar.tools_menu.trigger_label`.

Resolución de la etiqueta de un ítem, en orden: `name:` explícito → la clave del host
`topbar.tools_menu.items.<key>` si existe → la de la gema → `key.to_s.humanize`.

Esto **borra la última divergencia de identity**, cuyo único desvío en la vista es hoy usar
el prefijo `admin.nav.tools.*` en vez de `navigation.tools.*`.

## Lo que se queda en cada app

Unas 10 líneas, y son las que deben diferir:

```ruby
module InternalTools
  REPOSITORY_URL = "https://github.com/Grupo-AFAL/<app>"
  SENTRY_URL     = "https://icr-sa-de-cv.sentry.io/projects/<app>/"

  ALL = [ ... Bali::Topbar::ToolsMenu::Tool.new(..., meta: { gate: "system.admin" }) ... ]

  # SÓLO permisos. La disponibilidad la resuelve el componente contra su contexto de
  # vista, así que este método no necesita uno — se puede llamar desde cualquier lado.
  def self.visible_for(user)
    ALL.select { |t| user&.can?(t.meta[:gate]) }
  end
end
```

En identity, ese `visible_for` consulta `InternalToolsPolicy` en vez de `can?`, y sus `Tool`
no llevan `gate` en `meta`. La gema no nota la diferencia.

**Alternativa considerada para el gate:** un `Entry` local que envuelva `Tool` + gate, en
vez del hash libre `meta:`. Se descarta por ahora: agrega un objeto por app para transportar
un solo valor. Si `meta:` empieza a acumular claves, es la señal de reconsiderarlo.

## Testing

En la gema (`test/bali/components/topbar_tools_menu_test.rb`, estilo `ComponentTestCase`):

- No se renderiza con `tools: []`, ni cuando ninguna está `available?`.
- Descarta las no disponibles y conserva las disponibles.
- `route_helper` inexistente → no disponible; uno que el contexto sí conoce → disponible y
  su `href` es el que resuelve ese contexto. Se prueba con un **doble del contexto**, sin
  montar rutas: es la ventaja concreta de recibirlo en vez de buscarlo.
- `url` que resuelve a `nil` → no disponible.
- `in_app: true` → sin `target`; el resto → `target="_blank"` **y** `rel="noopener"`.
- `route_helper` + `url` juntos → `ArgumentError`.
- Etiquetas: `name:` gana sobre i18n; una clave desconocida cae en `humanize`.
- Accesibilidad: el trigger tiene nombre accesible (es un control de sólo ícono).

En cada app, las pruebas actuales **se conservan tal cual**: afirman sobre el HTML servido
(`.internal-tools-menu`, los `target`, qué ítems aparecen para quién) y esa es exactamente
la garantía que la migración no debe romper. Sólo cambia el selector de la clase raíz.

## Rollout

1. PR en Bali con componente, `Tool`, i18n, preview y pruebas. Versión **v3.2.0** (API
   nueva, sin cambios incompatibles).
2. Re-pin y migración app por app, cada una en su PR, con su suite en verde.

⚠️ **Los pines están dispersos** y el salto no es gratis:

| App | Bali hoy |
|---|---|
| afal-apps | v3.1.5 |
| gobierno-corporativo | v3.1.5 |
| opina | v3.1.5 (subió el 29/08) |
| **identity** | **v3.1.0** |

identity carga además el salto 3.1.0 → 3.2.0, con su propio riesgo ajeno a este cambio.

**Orden sugerido:** gobierno-corporativo primero — es la que tiene las seis herramientas,
las dos ramas de `in_app` y la suite más grande (10 730 pruebas), así que es la que más
rápido expone un hueco en la API. identity al final.

## Riesgos

- **La gema consulta las rutas del host.** Es lo que hace posible la regla del router, y es
  un acoplamiento que ningún otro componente de Bali tiene hoy. **Acotado en tres frentes:**
  (a) el contexto se **recibe**, no se busca — nada de `Rails.application`; (b) vive sólo en
  `Tool#available?`/`#href`, y `Component` no sabe de rutas más allá de delegar; (c) `Tool`
  es **opcional** — un host puede pasar herramientas con `url:` ya resuelta y no tocar la
  regla nunca. La alternativa de eliminarlo del todo (el host pasa `href:` y `available:`
  calculados) se descarta porque devuelve la regla a cuatro copias, que es lo que esta
  extracción viene a evitar.
- **`available?` deja de poder responderse fuera de un render.** Hoy las cuatro apps lo
  afirman en pruebas de modelo sin vista; esas pruebas se mudan a la gema, donde el
  componente sí renderiza. En las apps se conservan las de HTML servido, que son las que
  protegen el comportamiento de verdad.
- **Un `constraints` no impide que el route helper exista.** La compuerta responde "¿está
  montada?", no "¿este usuario pasa?". Es un límite conocido de las cuatro copias y se
  hereda tal cual; queda documentado en la API.
- **Migrar cuatro apps a la vez multiplica el radio.** Mitigación: una app por PR, y las
  pruebas de HTML servido de cada app son la red.

## Decisiones cerradas

Las dos preguntas que este spec dejó abiertas quedaron resueltas al aprobarse:

1. **El gate viaja en `meta:`**, un hash libre que la gema nunca lee. Se descarta el `Entry`
   local por app: agrega un objeto en cada repo para transportar un solo valor. Si `meta:`
   empieza a acumular claves, ésa es la señal de reconsiderarlo.
2. **La gema trae las etiquetas por defecto** de las seis claves conocidas, con override del
   host y `name:` explícito por herramienta. El costo aceptado es que la gema conozca seis
   claves de dominio; a cambio homologa los textos en las cuatro apps y borra el último
   desvío de identity (su prefijo `admin.nav.tools.*`).
