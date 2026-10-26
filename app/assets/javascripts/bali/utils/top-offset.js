// Keeps `element`'s top edge in the custom property `name` — its offset in the
// page, so scrolling does not move it, while a banner above it, a resize or a
// font loading does. The page's size changes whenever something above the
// element does; the element's own height changes it too, which leaves the
// offset as it was and so writes nothing. Returns the function that stops it.
// Bali::SplitView `height: :screen` (split_view/screen.js) and
// Bali::BpmnEditor `full_page:` fill the window below that edge with it.
export function observeTopOffset (element, name) {
  const measure = () => {
    const top = `${Math.round(element.getBoundingClientRect().top + window.scrollY)}px`
    if (element.style.getPropertyValue(name) !== top) element.style.setProperty(name, top)
  }
  const observer = new window.ResizeObserver(measure)
  observer.observe(document.body)
  window.addEventListener('resize', measure)
  measure()
  return () => {
    window.removeEventListener('resize', measure)
    observer.disconnect()
  }
}
