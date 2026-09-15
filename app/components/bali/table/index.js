import { Controller } from '@hotwired/stimulus'

// Pliega y despliega las filas de cada grupo de un `Bali::Table(collapsible_groups: true)`.
//
// El estado vive en el DOM y no en el controlador: el botón de cada banda lleva
// `aria-expanded` y las filas del grupo el atributo `hidden`. Así un restore de caché de
// Turbo lo conserva, y sin JS nada se esconde: el servidor nunca emite `hidden`, ni para los
// grupos que nacen plegados — los pliega este controlador al conectar, leyendo el
// `aria-expanded="false"` con el que salió su botón.
//
// Un valor de grupo que reaparece más abajo es EL MISMO grupo (mismo token, como en la
// selección): plegar una de sus bandas pliega las dos corridas y sincroniza los dos botones.
export class TableGroupsController extends Controller {
  static targets = ['trigger', 'row']

  // Cubre la carga inicial y las filas que llegan después —un Turbo Stream que reemplaza
  // la corrida—, para que aparezcan plegadas si su grupo lo está.
  rowTargetConnected (row) {
    const trigger = this.triggerFor(row.dataset.groupToken)

    if (trigger) row.hidden = !this.isExpanded(trigger)
  }

  toggle (event) {
    const token = event.currentTarget.dataset.groupToken
    const expanded = !this.isExpanded(event.currentTarget)

    this.triggersFor(token).forEach(trigger => trigger.setAttribute('aria-expanded', expanded))
    this.rowsFor(token).forEach(row => { row.hidden = !expanded })
  }

  isExpanded (trigger) {
    return trigger.getAttribute('aria-expanded') !== 'false'
  }

  triggerFor (token) {
    return this.triggersFor(token)[0]
  }

  triggersFor (token) {
    return this.triggerTargets.filter(trigger => trigger.dataset.groupToken === token)
  }

  rowsFor (token) {
    return this.rowTargets.filter(row => row.dataset.groupToken === token)
  }
}
