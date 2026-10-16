// `url` with `params` set on its query (empty values left out). Same-origin
// URLs come back as path + query + hash, the form a host writes in its
// templates; another origin is kept whole.
export function withParams (url, params, base = typeof window !== 'undefined' ? window.location.origin : 'http://localhost') {
  const target = new URL(url, base)
  for (const [key, value] of Object.entries(params)) if (value != null && value !== '') target.searchParams.set(key, value)
  return target.origin === new URL(base).origin ? target.pathname + target.search + target.hash : target.toString()
}
