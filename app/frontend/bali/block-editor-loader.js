/**
 * Bali Block Editor - Lazy loader
 *
 * Import once in the MAIN bundle (it weighs nothing):
 *
 *   import 'bali-view-components/block-editor-loader'
 *
 * The editor bundle is several MB of JS plus CSS: too heavy for the main
 * bundle, which travels on every page. But linking it from the form view does
 * not work either, because Bali drawers and modals inject their content with
 * fetch + innerHTML — and <script> tags inserted through innerHTML never
 * execute. The editor would stay unmounted: an empty div and no error.
 *
 * This module watches the DOM and, the first time an element with the
 * `block-editor` controller appears, injects the <link> and <script> for the
 * real bundle. The digested asset paths are only known server-side, so the
 * layout publishes them in two <meta> tags via the `block_editor_meta_tags`
 * helper.
 */
const SELECTOR = '[data-controller~="block-editor"]'
const JS_META = 'meta[name="bali-block-editor-js"]'
const CSS_META = 'meta[name="bali-block-editor-css"]'

let requested = false

const inject = (tag, attrs) => {
  const el = Object.assign(document.createElement(tag), attrs)
  document.head.appendChild(el)
}

const load = () => {
  if (requested) return
  requested = true

  const js = document.querySelector(JS_META)?.content
  const css = document.querySelector(CSS_META)?.content

  if (!js) {
    console.error(
      'Bali BlockEditor: an editor is on the page but the ' +
      '<meta name="bali-block-editor-js"> tag is missing. Add ' +
      '<%= block_editor_meta_tags %> to the <head> of your layout.'
    )
    return
  }

  if (css) inject('link', { rel: 'stylesheet', href: css })
  inject('script', { type: 'module', src: js })
}

const scan = (node) => {
  if (node?.nodeType !== Node.ELEMENT_NODE) return
  if (node.matches?.(SELECTOR) || node.querySelector?.(SELECTOR)) load()
}

const start = () => {
  scan(document.body)
  new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) scan(node)
    }
  }).observe(document.documentElement, { childList: true, subtree: true })
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', start, { once: true })
} else {
  start()
}
