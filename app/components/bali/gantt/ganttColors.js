// Color system of the Gantt island (#705, ported from afal-apps and decoupled
// from TDFlow via `catalogs` — decision D11). Every function returns INLINE
// style values (var(--color-*) / oklch) — never interpolated Tailwind classes,
// which v4 purges. Each color is a { solid, fill, border, text } set used to
// paint bar (fill+border), progress overlay (solid) and badges/legend
// uniformly across the color-by modes.
//
// The formulas live here alone since #970: Ruby's copy went with the renderer
// that used them. What Bali::Gantt::Colors still keeps is the DEFAULT STATUS
// MAP below, which a host inherits when it passes no catalog — a test reads
// this file and compares the two.

// Default catalogs: the island's historical status vocabulary (mirrors
// Bali::Gantt::Colors::DEFAULT_STATUS_VARS) and priority hues. Hosts pass
// their own `catalogs` prop built from their enums + i18n; these only kick in
// when they do not.
export const defaultCatalogs = {
  statuses: [
    { value: 'backlog', label: 'Backlog', color: null },
    { value: 'in_progress', label: 'In progress', color: '--color-info' },
    { value: 'ready_for_review', label: 'Ready for review', color: '--color-warning' },
    { value: 'complete', label: 'Complete', color: '--color-success' },
    { value: 'cancelled', label: 'Cancelled', color: null }
  ],
  priorities: [
    { value: 'urgent', label: 'Urgent', hue: 25 },
    { value: 'high', label: 'High', hue: 45 },
    { value: 'normal', label: 'Normal', hue: 70 },
    { value: 'low', label: 'Low', hue: null }
  ]
}

// Catalogs arrive as a Stimulus Object value; missing halves fall back to the
// defaults so a host can pass only `statuses`.
export function normalizeCatalogs (catalogs) {
  return {
    statuses: catalogs?.statuses?.length ? catalogs.statuses : defaultCatalogs.statuses,
    priorities: catalogs?.priorities?.length ? catalogs.priorities : defaultCatalogs.priorities
  }
}

// Hues cycled by root-group index for the "group" color-by mode.
export const GROUP_HUES = [259, 292, 35, 150, 200, 330]

export function neutralColor () {
  return {
    solid: 'color-mix(in oklch, var(--color-base-content) 42%, transparent)',
    fill: 'color-mix(in oklch, var(--color-base-content) 10%, transparent)',
    border: 'color-mix(in oklch, var(--color-base-content) 30%, transparent)',
    text: 'color-mix(in oklch, var(--color-base-content) 62%, transparent)'
  }
}

// Color from a daisyUI variable (status). `fill`/`border` derive by color-mix
// so no opaque token the theme might not define is needed.
function varColor (cssVar) {
  const c = `var(${cssVar})`
  return {
    solid: c,
    fill: `color-mix(in oklch, ${c} 16%, transparent)`,
    border: `color-mix(in oklch, ${c} 50%, transparent)`,
    text: c
  }
}

function statusEntry (status, catalogs) {
  return catalogs.statuses.find((s) => s.value === status)
}

export function statusColor (status, catalogs) {
  const entry = statusEntry(status, catalogs)
  return entry?.color ? varColor(entry.color) : neutralColor()
}

export function statusLabel (status, catalogs) {
  return statusEntry(status, catalogs)?.label || status
}

// Free-hue color (assignee/group/priority). null → neutral.
export function hueColor (hue) {
  if (hue == null) return neutralColor()
  return {
    solid: `oklch(0.62 0.15 ${hue})`,
    fill: `oklch(0.62 0.15 ${hue} / 0.15)`,
    border: `oklch(0.6 0.15 ${hue} / 0.5)`,
    text: `oklch(0.46 0.16 ${hue})`
  }
}

// Stable 0..359 hue from a string (assignee id/name). Same algorithm as
// Bali::Gantt::Colors.hash_hue so Ruby and JS color one assignee identically.
export function hashHue (value) {
  const s = String(value == null ? '' : value)
  let h = 0
  for (let i = 0; i < s.length; i += 1) h = (h * 31 + s.charCodeAt(i)) % 360
  return h
}

// Background color of the assignee avatar (solid, white text on top).
export function avatarColor (assignee) {
  if (!assignee) return 'color-mix(in oklch, var(--color-base-content) 30%, transparent)'
  return `oklch(0.6 0.14 ${hashHue(assignee.id ?? assignee.name)})`
}

function priorityHue (priority, catalogs) {
  return catalogs.priorities.find((p) => p.value === priority)?.hue ?? null
}

// Color of an item under the color-by mode. `groupIndex` = index of its root
// group (for the "group" mode). Returns { solid, fill, border, text }.
export function colorForItem (item, colorBy, { groupIndex = 0, catalogs }) {
  switch (colorBy) {
    case 'assignee':
      return item.assignee
        ? hueColor(hashHue(item.assignee.id ?? item.assignee.name))
        : neutralColor()
    case 'group':
      return hueColor(GROUP_HUES[groupIndex % GROUP_HUES.length])
    case 'priority':
      return hueColor(priorityHue(item.priority, catalogs))
    default:
      return statusColor(item.status, catalogs)
  }
}

// Footer legend entries for the mode. `ctx` carries the catalogs plus the
// data-derived lists:
//   ctx.catalogs  normalized { statuses, priorities }
//   ctx.groups    [{ name }] root groups in order (for the "group" mode)
//   ctx.assignees [{ id, name }] unique (for the "assignee" mode)
export function legendFor (colorBy, ctx) {
  const { catalogs, groups = [], assignees = [] } = ctx
  if (colorBy === 'assignee') {
    return assignees.map((a) => ({
      label: firstWord(a.name),
      color: `oklch(0.6 0.14 ${hashHue(a.id ?? a.name)})`
    }))
  }
  if (colorBy === 'group') {
    return groups.map((g, i) => ({
      label: firstWord(g.name),
      color: `oklch(0.62 0.15 ${GROUP_HUES[i % GROUP_HUES.length]})`
    }))
  }
  if (colorBy === 'priority') {
    return catalogs.priorities.map((p) => ({
      label: p.label || p.value,
      color: p.hue != null ? `oklch(0.62 0.15 ${p.hue})` : neutralColor().solid
    }))
  }
  return catalogs.statuses.map((s) => ({
    label: s.label || s.value,
    color: statusColor(s.value, catalogs).solid
  }))
}

function firstWord (name) {
  return String(name || '').split(/\s+/)[0] || '—'
}
