import { Controller } from '@hotwired/stimulus'

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
 * `filters#_submit` empuja la URL nueva al history ANTES de enviar el form, así que en el
 * momento del click `location.search` ya describe el recorte nuevo. También cubre la
 * restauración de caché de Turbo, donde el snapshot puede traer hrefs de otra visita.
 *
 *   <div data-controller="export-links">
 *     <a data-export-links-target="link" href="/movies?format=csv">CSV</a>
 *   </div>
 */
export default class extends Controller {
  static targets = ['link']

  connect () {
    this.sync()
    document.addEventListener('turbo:load', this.sync)
  }

  disconnect () {
    document.removeEventListener('turbo:load', this.sync)
  }

  sync = () => {
    const current = new URLSearchParams(window.location.search)
    // GEMELA EN RUBY: ToolbarHref::TRANSIENT_PARAMS. `format` se saca acá porque lo repone
    // cada link con el suyo — arrastrarlo daría el formato de la URL, no el del item.
    for (const key of ['page', 'clear_filters', 'clear_search', 'format']) current.delete(key)

    this.linkTargets.forEach((link) => {
      const url = new URL(link.href, window.location.origin)
      const format = url.searchParams.get('format')
      // Sin `format` el link no es un link de export: no hay nada que preservar y
      // reescribirlo lo convertiría en una copia de la URL actual.
      if (!format) return

      url.search = current.toString()
      url.searchParams.set('format', format)
      link.href = url.toString()
    })
  }
}
