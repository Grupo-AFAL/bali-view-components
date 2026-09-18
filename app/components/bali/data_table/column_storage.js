/**
 * La memoria POR DISPOSITIVO de la visibilidad de columnas de un DataTable.
 *
 * La escribe el selector de columnas y la lee también el control de vistas guardadas cuando
 * no hay selector en pantalla (tarjetas, calendario). Dos lectores derivando el formato por
 * su cuenta es exactamente cómo se pierden las columnas en silencio, así que el formato vive
 * en un solo archivo — mismo precedente que `popover_aria.js`.
 *
 * LA LLAVE NO CAMBIA: sigue siendo `bali:columns:<listing_id>` (`ListingIdentity`). Dos
 * pruebas de afal-apps comparan esa cadena exacta, y renombrarla dejaría huérfana la
 * preferencia de todo el mundo sin decirlo. Lo versionado es el VALOR.
 *
 * Formato v2:
 *
 *   { "v": 2, "hidden": [3], "known": [0, 1, 2, 3], "serverHidden": [3] }
 *
 * Tres listas, y ninguna sobra:
 *
 * - `known`: las columnas que el selector declaraba al escribir. Es el ESQUEMA, y es lo que
 *   permite no opinar sobre una columna que la memoria nunca vio. Ese es el defecto de #1144:
 *   v1 guardaba las VISIBLES y nada más, así que una columna agregada después no figuraba en
 *   la lista y nacía oculta, indistinguible de una escondida a propósito.
 * - `hidden`: las que NO se veían en ese momento. Estado resuelto, no decisión.
 * - `serverHidden`: las que el ANFITRIÓN declaraba ocultas en ese momento
 *   (`with_column(visible: false)`). Es la línea base contra la que se lee `hidden`.
 *
 * La decisión del usuario es la DIFERENCIA entre las dos últimas, y esa distinción es la que
 * hace que la memoria no reclame lo que no eligió nadie:
 *
 *   hidden ∧ ¬serverHidden → el usuario la escondió     → ocultar
 *   ¬hidden ∧ serverHidden → el usuario la mostró       → mostrar
 *   hidden = serverHidden  → coinciden: no hay decisión → manda el servidor
 *   ∉ known                → la memoria nunca la vio    → manda el servidor
 *
 * Sin `serverHidden` la tercera fila no existe: una columna que el anfitrión declaró
 * `visible: false` y que el usuario nunca tocó quedaría registrada como preferencia SUYA en la
 * primera escritura, y a partir de ahí un `visible: true` del anfitrión no le llegaría nunca.
 * Es la misma forma de falla de #1144, más angosta, y no hace falta que el usuario toque nada
 * para caer en ella: la escritura de migración basta.
 *
 * De ahí que leer tenga TRES respuestas y no dos: oculta, visible, o sin opinión.
 */

export const COLUMN_STORAGE_VERSION = 2

// Techo del rango que se infiere de un valor v1 (abajo): los índices válidos son 0..255. Una
// tabla real no llega ni cerca; está para que un valor corrupto —`[999999999]` escrito por
// cualquier otra cosa— no arme un array de mil millones de entradas y cuelgue la página en vez
// de ignorarse.
const MAX_TRACKED_COLUMNS = 256

// Índices de columna saneados: enteros, no negativos, bajo el techo, sin repetidos y
// ordenados. El valor viene de `localStorage`, o sea de fuera del programa: puede traer
// cualquier cosa.
const columnIndices = (value) => {
  if (!Array.isArray(value)) return []

  const seen = new Set()
  for (const entry of value) {
    const index = parseInt(entry, 10)
    if (!isNaN(index) && index >= 0 && index < MAX_TRACKED_COLUMNS) seen.add(index)
  }

  return [...seen].sort((a, b) => a - b)
}

/**
 * v1 era un array pelado de índices VISIBLES, sin registro de qué columnas existían al
 * escribirlo. Lo único que ese valor DEMUESTRA conocer es hasta su índice más alto: por
 * encima de él no hay evidencia de que la columna existiera cuando se guardó.
 *
 * Esa es la inferencia máxima que el formato soporta, y resuelve el empate a favor del
 * criterio del issue —una columna nueva se ve sin tocar preferencias— al precio, medido y
 * acotado, de olvidar UNA vez la preferencia sobre la última columna de la tabla si era justo
 * la que el usuario tenía escondida: esa es indistinguible de una columna que no existía.
 * Lo que está debajo del techo se conserva entero.
 *
 * Tampoco registraba lo que el servidor declaraba, así que `serverHidden` sale `null`: línea
 * base desconocida. Quien lee decide con qué la reemplaza — el selector usa la declaración
 * VIGENTE del servidor, que es el mejor dato disponible y el único que no le atribuye al
 * usuario una columna que el anfitrión ya traía oculta.
 *
 * Caso límite: un v1 vacío (`[]`, el usuario había escondido TODAS las columnas) no demuestra
 * conocer ninguna, así que no se migra nada y la tabla vuelve a sus defaults. Una tabla sin
 * columnas visibles no es un estado que valga la pena conservar a ciegas.
 */
const fromLegacy = (visible) => {
  const ceiling = Math.max(-1, ...visible)
  const known = []
  for (let index = 0; index <= ceiling; index++) known.push(index)

  return {
    hidden: known.filter((index) => !visible.includes(index)),
    known,
    serverHidden: null,
    stale: true
  }
}

/**
 * Lee la memoria de `key`. Devuelve `{ hidden, known, serverHidden, stale }` —siempre en la
 * forma v2, sea cual sea el formato guardado— o `null` cuando no hay nada legible.
 *
 * `serverHidden` es `null` cuando el valor guardado no registró la línea base: todo v1, y
 * también un v2 al que le falte la lista. `stale: true` avisa que conviene reescribirlo para
 * no repetir la inferencia en cada carga; nadie está obligado a hacerlo.
 *
 * Una versión futura (v3) se lee como `null`: mejor volver a los defaults del servidor que
 * interpretar mal un formato que este código no conoce.
 */
export function readColumnState (key) {
  if (!key) return null

  let raw
  try {
    raw = window.localStorage.getItem(key)
  } catch { return null }
  if (!raw) return null

  let parsed
  try {
    parsed = JSON.parse(raw)
  } catch { return null }

  if (Array.isArray(parsed)) return fromLegacy(columnIndices(parsed))
  if (!parsed || parsed.v !== COLUMN_STORAGE_VERSION) return null

  const baseline = Array.isArray(parsed.serverHidden) ? columnIndices(parsed.serverHidden) : null

  return {
    hidden: columnIndices(parsed.hidden),
    known: columnIndices(parsed.known),
    serverHidden: baseline,
    stale: baseline === null
  }
}

export function writeColumnState (key, { hidden, known, serverHidden }) {
  if (!key) return

  const value = {
    v: COLUMN_STORAGE_VERSION,
    hidden: columnIndices(hidden),
    known: columnIndices(known),
    serverHidden: columnIndices(serverHidden)
  }

  try {
    window.localStorage.setItem(key, JSON.stringify(value))
  } catch { /* almacenamiento lleno o bloqueado: la sesión sigue sin persistir */ }
}

/**
 * Las columnas VISIBLES según la memoria, o `null` si no hay memoria. Es lo que necesita el
 * payload de una vista guardada, que sigue siendo —a propósito— una lista de visibles: ver el
 * comentario de `saved_views_controller#storedColumns`.
 *
 * Sale de `known \ hidden`, o sea del estado RESUELTO y no de las decisiones: una columna que
 * el anfitrión declaró oculta y el usuario nunca tocó no se ve, y por eso tampoco entra en la
 * vista. Sobre un estado migrado de v1 devuelve exactamente el array que estaba guardado, así
 * que el contrato con el servidor no se mueve.
 */
export function visibleColumns (state) {
  if (!state) return null

  return state.known.filter((index) => !state.hidden.includes(index))
}
