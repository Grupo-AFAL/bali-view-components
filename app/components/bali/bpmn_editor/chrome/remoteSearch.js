import { get } from '@rails/request.js'

// GET `url` with the given query params; the host answers an array of
// { id, label, description, url, group }. Resolves { ok: true, items } or,
// when the request fails or the answer is not an array, { ok: false } — the
// panel says so instead of showing "No results". It never rejects: a search
// box that throws would take the panel down with it.
export async function remoteSearch (url, params) {
  const target = new URL(url, window.location.origin)
  for (const [key, value] of Object.entries(params)) if (value != null && value !== '') target.searchParams.set(key, value)
  try {
    const response = await get(target.toString(), { responseKind: 'json' })
    if (!response.ok) return { ok: false }
    const body = await response.json
    return Array.isArray(body) ? { ok: true, items: body } : { ok: false }
  } catch {
    return { ok: false }
  }
}

export function groupBy (items) {
  const groups = new Map()
  for (const item of items) {
    const key = item.group || ''
    if (!groups.has(key)) groups.set(key, [])
    groups.get(key).push(item)
  }
  return [...groups.entries()]
}
