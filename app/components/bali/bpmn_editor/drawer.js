// Opens a host URL in the Bali drawer of the layout, through its `drawer`
// controller and a synthetic <a href> — the same mechanism as the Gantt's
// openDrawerUrl (GanttFlow.jsx). Without a drawer on the page it navigates.
export function openDrawerUrl (url) {
  if (!url || typeof document === 'undefined') return
  const app = window.Stimulus
  const host = document.querySelector('[data-controller~="drawer"]')
  const controller = app && host ? app.getControllerForElementAndIdentifier(host, 'drawer') : null
  if (controller && typeof controller.open === 'function') {
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.setAttribute('data-turbo', 'false')
    try {
      // `open` is async and fetches inside: a network failure is a rejected
      // promise, so the fallback hangs off the promise.
      Promise.resolve(controller.open({ preventDefault () {}, currentTarget: anchor }))
        .catch(() => window.location.assign(url))
      return
    } catch {
      // the drawer failed outright: navigate instead.
    }
  }
  window.location.assign(url)
}
