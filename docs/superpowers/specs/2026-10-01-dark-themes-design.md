# Modo oscuro: temas validados e interruptor en el menú de usuario — Design

Date: 2026-10-01
Status: Approved (brainstorming) — 2026-10-01

## Purpose

Las apps del grupo no tienen modo oscuro. Bali ya trae `afal-dark`, pero como borrador que nadie
validó ni activa, y Costa Norte no tiene tema oscuro en Bali: la app costa-norte define un
`costa-norte-dark` propio sólo para pintar oscuro su menú lateral.

Este diseño entrega dos temas oscuros validados —uno para AFAL y otro para Costa Norte— y una
forma de que cada persona elija claro u oscuro desde el menú de usuario, sin que ninguna app
cambie hasta que lo active.

## Decisiones (de la sesión de brainstorming)

| Pregunta | Decisión |
|---|---|
| Cómo llega la persona al modo oscuro | Un interruptor; vive en el menú de usuario (`Bali::Topbar::UserMenu`), no en el Topbar |
| Dónde se recuerda la elección | Una cookie del navegador, que el servidor lee para pintar la página ya en oscuro |
| Qué ve quien no ha elegido | Claro. El interruptor tiene dos posiciones: claro y oscuro |
| De dónde sale el Costa Norte oscuro | Del `costa-norte-dark` que la app ya usa en su menú lateral, completado a tema entero |

## 1. Los temas

**`afal-dark`** existe en `app/assets/stylesheets/bali/themes/afal-dark.css`. Se valida completo
(sección 4) y se ajustan los tokens que no pasen. Tras la aprobación visual, su cabecera deja de
decir «DRAFT / EXPERIMENTAL».

**`costa-norte-dark`** es nuevo en `app/assets/stylesheets/bali/themes/costa-norte-dark.css`. Parte
de los valores que costa-norte tiene hoy en `app/assets/tailwind/application.css` (superficies
teal oscuras, primario dorado, texto claro) **sin cambiarlos**, para que la app pueda borrar su
bloque al subir de versión y su menú lateral se vea igual. Se completa con lo que un tema entero
necesita y se valida igual que `afal-dark`.

Los dos se publican por el mismo `exports` de `package.json` que ya sirve `css/themes/*.css`, así
que una app los importa con `@import "bali-view-components/css/themes/<tema>.css";`.

## 2. Adopción en una app

Tres cambios por app, que el CHANGELOG nombra:

1. **Configuración.** En `config/initializers/bali.rb`:
   `Bali.themes = { light: "afal", dark: "afal-dark" }` (costa-norte: `costa-norte` /
   `costa-norte-dark`). Sin esta línea nada cambia: no hay interruptor y el helper devuelve el
   tema claro.
2. **Layout.** `<html data-theme="afal">` pasa a `<html data-theme="<%= bali_theme %>">`.
   `bali_theme` (helper de Bali expuesto a las vistas del host, como `react_island_meta_tags`)
   lee la cookie y devuelve el tema claro u oscuro configurado. Lo decide el servidor: la página
   llega ya en oscuro, sin parpadeo.
3. **Variante `dark:` de Tailwind.** La línea `@custom-variant dark (...)` de la app suma su tema
   oscuro, para que las clases `dark:` también se activen con él.

**La cookie** se llama `bali_theme` y guarda `light` o `dark`, con `path=/`, un año y
`SameSite=Lax`. No es `HttpOnly`: la escribe el JS del interruptor. Nombre y valores son un
contrato entre Ruby (que la lee) y JS (que la escribe): mismo patrón en los dos lados, cada uno
nombrando al otro y con una prueba de cada lado. Cualquier otro valor se lee como claro.

**Límite conocido:** la elección es por app y por dispositivo; cada app vive en su dominio y una
cookie no lo cruza. Una preferencia de flota pediría guardarla en la cuenta (Pasaporte), fuera de
este diseño.

## 3. El interruptor

- **Dónde:** un ítem de `Bali::Topbar::UserMenu`, entre los ítems de la app y «Cerrar sesión».
  Sólo se pinta si `Bali.themes` declara un tema `dark:`.
- **Cómo se ve:** «Modo oscuro» con un ícono de luna y un interruptor visual a la derecha que
  muestra el estado. La etiqueta no cambia con el estado.
- **Accesibilidad:** un `<button role="menuitemcheckbox" aria-checked="true|false">`. El
  controlador del dropdown recorre con las flechas los `menuitem*`, no sólo los `menuitem`, así
  que el ítem entra en el teclado que dejó #1244.
- **Qué hace:** un controlador Stimulus cambia `data-theme` del `<html>` al otro tema del par,
  escribe la cookie y actualiza `aria-checked`, sin recargar. El menú se queda abierto (un clic
  dentro del menú no lo cierra), así que la persona ve el cambio y puede deshacerlo.
- **Los nombres de los temas** viajan del Ruby al controlador como values de Stimulus, desde
  `Bali.themes`; no están escritos en el JS.
- **Textos:** `bali_view.topbar.user_menu.dark_mode` — «Modo oscuro» / «Dark mode».
- **Fuera de alcance:** un interruptor suelto fuera del menú de usuario. identity, la única app
  sin `UserMenu`, migra su topbar en Grupo-AFAL/identity#350.

## 4. Validación

- **Barrido de contraste** de todos los previews de Lookbook en `afal-dark` y `costa-norte-dark`,
  con pintado real (`paintedContrast`, que compone alfa, opacidad y fondos translúcidos): texto a
  4.5:1. Lo que falle por el tema se corrige en el tema; lo que sea receta de un componente va a
  un issue aparte.
- **Guardias permanentes:** una sola lista de temas en `cypress/support/`, que las guardias de
  contraste comparten y que suma `costa-norte-dark` (resuelve la parte de la lista duplicada de
  #1252). `test/bali/themes_test.rb` exige el archivo nuevo y su completitud.
- **ThemeSampler:** página de `costa-norte-dark` junto a la de `afal-dark`; capturas de los dos
  para la aprobación visual.
- **Pruebas del interruptor:** Minitest (el helper según la cookie y la configuración; el ítem
  sólo con `dark:` configurado; su marcado) y Cypress (el clic cambia el tema y escribe la cookie;
  al recargar sigue oscuro; `aria-checked`; teclado). Cada una con su control negativo.

## 5. Lanzamiento

1. Bali publica los temas y el interruptor; ninguna app cambia hasta configurarlo.
2. El CHANGELOG lleva los tres pasos de la sección 2.
3. Se activa primero en una app piloto de AFAL y en costa-norte, y se prueba en uso real antes de
   extenderlo.
