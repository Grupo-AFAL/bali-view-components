import { Controller } from '@hotwired/stimulus'

// GEMELA EN RUBY: `Bali::DataTable::ToolbarHref::TRANSIENT_PARAMS`. Un test lee este literal
// y lo compara contra la constante de Ruby: moverla de un lado sin el otro dejaba las dos
// mitades del mismo link en desacuerdo y no fallaba nada.
const TRANSIENT_PARAMS = ['page', 'clear_filters', 'clear_search']

// Un submit de filtros responde `turbo_stream` y reemplaza SOLO el nodo del listado: no hay
// visita, así que Turbo NO dispara `turbo:load` y este controlador tampoco se reconecta —
// vive fuera del nodo reemplazado. Escuchar solo esa señal dejaba el href congelado justo en
// el caso para el que existe. `turbo:before-stream-render` es el que cubre esa rama;
// `turbo:submit-end` cubre el submit que ni navega ni streamea (una respuesta de frame).
const SYNC_EVENTS = ['turbo:load', 'turbo:before-stream-render', 'turbo:submit-end']

/**
 * Export Links Controller
 *
 * Mantiene los href del export apuntando al recorte que el usuario está mirando.
 *
 * El server ya los pinta bien en una carga completa o en una visita de Turbo Drive, pero el
 * export vive en el ⋯ del PageHeader — FUERA del nodo que el turbo_stream de un submit de
 * filtros reemplaza. Sin esto, el primer filtro deja el href congelado con el recorte de la
 * carga inicial: el mismo bug de "exporté lo filtrado y me llevé todo", otra vez en silencio.
 *
 * `filters#_submit` empuja la URL nueva al history ANTES de enviar el form, así que cuando
 * cualquiera de los SYNC_EVENTS llega `location.search` ya describe el recorte nuevo.
 * También cubre la restauración de caché de Turbo, donde el snapshot puede traer hrefs de
 * otra visita.
 *
 *   <div data-controller="export-links">
 *     <a data-export-links-target="link" href="/movies?format=csv">CSV</a>
 *   </div>
 */
export default class extends Controller {
  static targets = ['link']

  // `false` cuando el server pintó el recorte a mano (ver `params:` en with_export): ahí el
  // href no es una foto de la URL sino una decisión del host.
  static values = { sync: { type: Boolean, default: true } }

  connect () {
    this.sync()
    SYNC_EVENTS.forEach(name => document.addEventListener(name, this.sync))
  }

  disconnect () {
    SYNC_EVENTS.forEach(name => document.removeEventListener(name, this.sync))
  }

  sync = () => {
    // Con `params:` explícito el host ya decidió qué exportar —incluido `{}`, que es el
    // opt-out de "exportar todo a propósito"—, así que adivinarlo desde la URL se lo deshace
    // apenas bootea Stimulus, sin que nada lo delate.
    if (!this.syncValue) return

    const current = new URLSearchParams(window.location.search)

    this.linkTargets.forEach((link) => {
      const url = new URL(link.href, window.location.origin)
      const format = url.searchParams.get('format')
      // Sin `format` el link no es un link de export: no hay nada que preservar y
      // reescribirlo lo convertiría en una copia de la URL actual.
      if (!format) return

      link.href = this.mergedHref(url, current, format)
    })
  }

  /**
   * El MISMO merge que `ToolbarHref#build_toolbar_href` hace en Ruby: la URL del navegador
   * pisa la clave entera (como `Hash#merge`, sin intercalar valores de una clave repetida),
   * pero lo que el host puso en la `url:` y el navegador no trae sobrevive. Reemplazar el
   * query string de una lo borraba: un `url: exports_path(kind: :movies)` salía sin `kind` y
   * el export apuntaba a otro set — lo contrario de lo que el server había servido.
   */
  mergedHref (url, current, format) {
    const merged = new URLSearchParams(url.search)

    for (const key of new Set(current.keys())) {
      merged.delete(key)
      current.getAll(key).forEach(value => merged.append(key, value))
    }
    // Se tiran del resultado MERGEADO, como el `.except` de Ruby: un `page` que venga de la
    // `url:` del host exporta una página igual que si viniera del navegador.
    TRANSIENT_PARAMS.forEach(key => merged.delete(key))
    merged.set('format', format)

    url.search = merged.toString()
    return url.toString()
  }
}
