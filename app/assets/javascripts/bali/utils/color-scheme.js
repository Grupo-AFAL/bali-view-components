// The scheme the host page declares on `<html>`, as Bali's themes do. `only dark` is
// still dark; `light dark` leaves it to the operating system, which is not a choice
// the person made in this app.
export function hostColorScheme () {
  const scheme = getComputedStyle(document.documentElement).colorScheme

  return scheme.replace('only', '').trim() === 'dark' ? 'dark' : 'light'
}

// Calls `callback` with the new scheme when <html data-theme> is switched in place
// (Bali::Topbar::UserMenu) to a theme of the other scheme — `afal` to `light` calls nothing.
// Returns the observer, for the caller to disconnect.
export function observeHostColorScheme (callback) {
  let scheme = hostColorScheme()

  const observer = new MutationObserver(() => {
    const next = hostColorScheme()
    if (next === scheme) return

    scheme = next
    callback(next)
  })
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] })

  return observer
}
