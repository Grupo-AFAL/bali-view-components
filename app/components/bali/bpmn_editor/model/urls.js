// `url` with `params` set on its query (empty values left out). Same-origin
// URLs come back as path + query + hash, the form a host writes in its
// templates; another origin is kept whole.
export function withParams (url, params, base = typeof window !== 'undefined' ? window.location.origin : 'http://localhost') {
  const target = new URL(url, base)
  for (const [key, value] of Object.entries(params)) if (value != null && value !== '') target.searchParams.set(key, value)
  return target.origin === new URL(base).origin ? target.pathname + target.search + target.hash : target.toString()
}

// A URL from the document (a reference's, a lane assignee's) or from a host
// search, as an href or a navigation: a path or http(s), else null. A
// `javascript:` one would run on a click — React renders it as an href and
// Turbo.visit falls back to `window.location`. The URL parser decides the
// scheme, as the browser would ("java\tscript:" included). Mirrors
// Bali::BpmnEditor::Data#navigable_url! (contract_test.rb).
export const NAVIGABLE_SCHEMES = ['http', 'https']
export function safeUrl (url) {
  if (typeof url !== 'string' || !url.trim()) return null
  try {
    return NAVIGABLE_SCHEMES.includes(new URL(url, 'http://localhost').protocol.slice(0, -1)) ? url : null
  } catch {
    return null
  }
}
