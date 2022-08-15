export function destroyWithCheck (id) {
  var slim = id
    ? document.querySelector('.' + id + '.ss-main')
    : this.slim.container
  var select = id
    ? document.querySelector('[data-ssid='.concat(id, ']'))
    : this.select.element

  // If there is no slim dont do anything
  if (!slim || !select) {
    return
  }

  document.removeEventListener('click', this.documentClick)

  if (this.config.showContent === 'auto') {
    window.removeEventListener('scroll', this.windowScroll, false)
  }

  // Show original select
  select.style.display = ''
  delete select.dataset.ssid

  // Remove slim from original select dropdown
  var el = select
  el.slim = null

  // Remove slim select
  if (slim.parentElement) {
    slim.parentElement.removeChild(slim)
  }

  // remove the content if it was added to the document body
  if (this.config.addToBody) {
    var slimContent = id
      ? document.querySelector('.' + id + '.ss-content')
      : this.slim.content

    // FIX: This is the fix why we needed to override the destroy function
    // The original only checks for the presence of the slimContent variable
    // but does not check it is actually present in the document.
    //
    // https://github.com/brianvoe/slim-select/blob/master/src/slim-select/index.ts#L521
    if (!document.body.contains(slimContent)) {
      return
    }

    document.body.removeChild(slimContent)
  }
}
