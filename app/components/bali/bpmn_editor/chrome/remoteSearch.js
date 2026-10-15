import { get } from '@rails/request.js'

// GET `url` with the given query params; the host answers an array of
// { id, label, description, url, group }. Errors resolve to [] — a search box
// that throws would take the panel down with it.
export async function remoteSearch (url, params) {
  const target = new URL(url, window.location.origin)
  for (const [key, value] of Object.entries(params)) if (value != null && value !== '') target.searchParams.set(key, value)
  try {
    const response = await get(target.toString(), { responseKind: 'json' })
    if (!response.ok) return []
    const body = await response.json
    return Array.isArray(body) ? body : (Array.isArray(body && body.results) ? body.results : [])
  } catch {
    return []
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
