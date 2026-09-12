// Builds the row-set, the React Flow nodes/edges and the summary bars from
// the Bali::Gantt data contract (#705): `groups` (one nesting level via
// parent_id), `items` (sub-items via parent_id) ordered by the server, plus
// `dependencies` and `critical_ids`. The schedule and the critical path are
// the SERVER's; React only maps date<->x, sorts/collapses/filters rows and
// numbers the WBS.
//
// SINGLE SOURCE OF ROWS (tree<->bars alignment): `buildRows` produces the
// ORDERED and FILTERED list (collapse + search + status filter) of visible
// rows. BOTH the left table AND the bars (nodes) derive from THIS array and
// the same `rowIndex`, so row N of the table sits at the height of the bar at
// y=rowY(N). Collapsing/hiding a row affects both sides at once.
import { useMemo } from 'react'
import { MarkerType } from '@xyflow/react'
import { dateToX, durationDays } from './timeScale'

export const ROW_H = 36 // row height (px). Constant with the canvas snapGrid.
export const BAR_H = 24 // bar height inside the row.
// Prefix of dependency edge ids: `${DEP_PREFIX}${dependency.id}`. Shared with
// GanttFlow to rebuild the dependency id on delete (no magic numbers).
export const DEP_PREFIX = 'dep-'

// Y (px) of the bar given its row. Reused by GanttFlow to LOCK the vertical
// axis during drags (React Flow has no native axis lock).
export function rowY (rowIndex) {
  return rowIndex * ROW_H + (ROW_H - BAR_H) / 2
}

// Collapse key of a group/item row. Prefixed so group ids cannot collide with
// item ids (distinct numeric spaces share values).
export function groupKey (id) {
  return `group-${id}`
}
export function itemKey (id) {
  return `item-${id}`
}

// End date used for drawing: a milestone with no explicit end renders as a
// single-day diamond on its date instead of falling out of the canvas.
export function drawnEndsOn (item) {
  return item.ends_on || (item.milestone ? item.starts_on : null)
}

// Flattens groups→(sub-groups)→items→sub-items into an ordered list of
// visible rows, honoring collapse AND filtering (name search + status
// filter). Numbers the WBS (1, 1.1, 1.1.1) over the ORIGINAL hierarchy
// (stable under filtering) and annotates `groupIndex` (index of the ROOT
// group — sub-groups inherit their parent's for the "group" color-by).
// Returns one row per visible entry with its final gap-free `rowIndex` — the
// same index the bars use, so table and bars stay aligned 1:1.
//
// Row kinds:
//   { kind: 'group',   id, name, status, depth:0|1, groupIndex, wbs, hasChildren, collapsed }
//   { kind: 'item',    id, item, depth:1|2, groupIndex, wbs, hasChildren, collapsed }
//   { kind: 'subitem', id, item, depth:2|3, groupIndex, wbs }
export function buildRows ({ groups = [], items = [], collapsedIds, search = '', filterStatus = 'all' }) {
  const collapsed = collapsedIds || new Set()
  const query = String(search || '').trim().toLowerCase()
  const filtering = query !== '' || (filterStatus && filterStatus !== 'all')
  const matches = (item) => {
    if (!item) return false
    if (filterStatus && filterStatus !== 'all' && item.status !== filterStatus) return false
    if (query && !String(item.name || '').toLowerCase().includes(query)) return false
    return true
  }

  // Group items by group and by parent, preserving server order.
  const topByGroup = new Map()
  const childrenByParent = new Map()
  for (const item of items) {
    if (item.parent_id) {
      if (!childrenByParent.has(item.parent_id)) childrenByParent.set(item.parent_id, [])
      childrenByParent.get(item.parent_id).push(item)
    } else {
      if (!topByGroup.has(item.group_id)) topByGroup.set(item.group_id, [])
      topByGroup.get(item.group_id).push(item)
    }
  }

  // A document without groups still renders: synthesize one implicit group per
  // group_id found (id as name) so ungrouped hosts get a flat board.
  const visibleGroups =
    groups.length > 0
      ? groups
      : [...new Set(items.filter((i) => !i.parent_id).map((i) => i.group_id))].map((id) => ({
          id,
          name: id == null ? '' : String(id),
          status: null
        }))

  // Root groups in server order; sub-groups gathered under their parent. A
  // sub-group whose parent is absent from the list (orphan) is treated as a
  // root so its items are not lost.
  const rootIds = new Set(visibleGroups.filter((g) => !g.parent_id).map((g) => g.id))
  const rootGroups = []
  const subsByParent = new Map()
  for (const g of visibleGroups) {
    if (g.parent_id && rootIds.has(g.parent_id)) {
      if (!subsByParent.has(g.parent_id)) subsByParent.set(g.parent_id, [])
      subsByParent.get(g.parent_id).push(g)
    } else {
      rootGroups.push(g)
    }
  }

  const rows = []
  let i = 0
  const push = (row) => {
    rows.push({ ...row, rowIndex: i })
    i += 1
  }

  // Items visible under the filter for a group (the item or any sub-item).
  const visibleTopFor = (groupId) => {
    const topItems = topByGroup.get(groupId) || []
    return topItems.filter((item) => {
      if (!filtering) return true
      if (matches(item)) return true
      return (childrenByParent.get(item.id) || []).some(matches)
    })
  }

  // Item→sub-item rows of a group/sub-group, under the given WBS and depth.
  const pushItemRows = (groupId, groupIndex, baseWbs, baseDepth) => {
    const topItems = topByGroup.get(groupId) || []
    visibleTopFor(groupId).forEach((item) => {
      // WBS by ORIGINAL position within the group (stable under filtering).
      const tj = topItems.indexOf(item)
      const subItems = childrenByParent.get(item.id) || []
      const itemCollapsed = collapsed.has(itemKey(item.id))
      push({
        kind: 'item',
        id: item.id,
        item,
        depth: baseDepth,
        groupIndex,
        wbs: `${baseWbs}.${tj + 1}`,
        hasChildren: subItems.length > 0,
        collapsed: itemCollapsed
      })
      if (itemCollapsed) return

      subItems.forEach((sub, sk) => {
        if (filtering && !matches(sub) && !matches(item)) return
        push({
          kind: 'subitem',
          id: sub.id,
          item: sub,
          depth: baseDepth + 1,
          groupIndex,
          wbs: `${baseWbs}.${tj + 1}.${sk + 1}`
        })
      })
    })
  }

  rootGroups.forEach((group, gi) => {
    const subGroups = subsByParent.get(group.id) || []
    const ownTop = topByGroup.get(group.id) || []
    const visibleOwn = visibleTopFor(group.id)
    const visibleSubs = filtering
      ? subGroups.filter((sub) => visibleTopFor(sub.id).length > 0)
      : subGroups
    if (filtering && visibleOwn.length === 0 && visibleSubs.length === 0) return

    const groupCollapsed = collapsed.has(groupKey(group.id))
    push({
      kind: 'group',
      id: group.id,
      name: group.name,
      status: group.status,
      depth: 0,
      groupIndex: gi,
      wbs: String(gi + 1),
      hasChildren: ownTop.length > 0 || subGroups.length > 0,
      collapsed: groupCollapsed
    })
    if (groupCollapsed) return

    pushItemRows(group.id, gi, String(gi + 1), 1)

    // Sub-groups after the direct items; their WBS continues the group's
    // numbering (n.m) BY ORIGINAL position among siblings (stable under
    // filtering, like topItems.indexOf) and inherits the parent's groupIndex.
    visibleSubs.forEach((sub) => {
      const subWbs = `${gi + 1}.${ownTop.length + subGroups.indexOf(sub) + 1}`
      const subCollapsed = collapsed.has(groupKey(sub.id))
      push({
        kind: 'group',
        id: sub.id,
        name: sub.name,
        status: sub.status,
        depth: 1,
        groupIndex: gi,
        wbs: subWbs,
        hasChildren: (topByGroup.get(sub.id) || []).length > 0,
        collapsed: subCollapsed
      })
      if (subCollapsed) return

      pushItemRows(sub.id, gi, subWbs, 2)
    })
  })

  return rows
}

// Derives rows + nodes + edges + summaryBars from the current schedule
// (server authoritative). Memoized over the relevant inputs plus
// collapse/search/filter.
//
// `criticalIds` is the document's top-level `critical_ids` array (CPM
// output): after a reconcile it reflects the FRESH critical path even though
// nodes are set from positions.
export function useGanttModel ({
  groups = [],
  items = [],
  dependencies = [],
  window: win = {},
  pixelsPerDay,
  criticalIds = null,
  collapsedIds = null,
  search = '',
  filterStatus = 'all'
}) {
  const pxPerDay = pixelsPerDay || 24
  const windowStart = win.starts_on
  // Stable keys for the memo (a fresh array/Set per render would break equality).
  const criticalKey = criticalIds ? criticalIds.join(',') : null
  const collapsedKey = collapsedIds ? [...collapsedIds].sort().join(',') : ''

  return useMemo(() => {
    const collapsed = collapsedIds || new Set()
    const rows = buildRows({ groups, items, collapsedIds: collapsed, search, filterStatus })

    const critical = new Set((criticalIds || []).map((id) => String(id)))

    // Position of ALL scheduled items (not only visible ones) → the summary
    // bars of a collapsed group still show their rollup.
    const posByItemId = new Map()
    if (windowStart) {
      for (const item of items) {
        const endsOn = drawnEndsOn(item)
        if (!item.starts_on || !endsOn) continue
        const x = dateToX(item.starts_on, windowStart, pxPerDay)
        const width = durationDays(item.starts_on, endsOn) * pxPerDay
        posByItemId.set(String(item.id), {
          x,
          width,
          groupId: item.group_id,
          critical: critical.has(String(item.id))
        })
      }
    }

    // One bar per VISIBLE item/subitem row with a drawable range.
    const nodes = rows
      .filter((r) => r.kind !== 'group' && r.item.starts_on && drawnEndsOn(r.item) && windowStart)
      .map((r) => {
        const item = r.item
        const x = dateToX(item.starts_on, windowStart, pxPerDay)
        const width = durationDays(item.starts_on, drawnEndsOn(item)) * pxPerDay
        const isCritical = critical.has(String(item.id))
        return {
          id: String(item.id),
          type: 'taskBar',
          position: { x, y: rowY(r.rowIndex) },
          width,
          height: BAR_H,
          data: { ...item, is_critical: isCritical, rowIndex: r.rowIndex, groupIndex: r.groupIndex, barWidth: width },
          className: isCritical ? 'critical' : ''
        }
      })

    const nodeIds = new Set(nodes.map((n) => n.id))

    // One arrow per dependency between items that DO have bars (both visible).
    const edges = dependencies
      .filter((d) => nodeIds.has(String(d.predecessor_id)) && nodeIds.has(String(d.successor_id)))
      .map((d) => {
        const source = String(d.predecessor_id)
        const target = String(d.successor_id)
        const isCritical = critical.has(source) && critical.has(target)
        return {
          id: `${DEP_PREFIX}${d.id}`,
          source,
          target,
          sourceHandle: 'out', // flush to the predecessor's right edge
          targetHandle: 'in', // flush to the successor's left edge
          type: 'smoothstep',
          markerEnd: { type: MarkerType.ArrowClosed },
          // The `critical` className is a FEATURE (D10): flow.css strokes the
          // edge with var(--color-error) so CPM information is not lost.
          className: isCritical ? 'critical' : ''
        }
      })

    // Summary bar per VISIBLE group: min-start → max-end range over the
    // group's items AND its sub-groups' items (all of them, not only the
    // visible ones), plus whether any is critical. A group with no dated
    // items falls back to its own dates (starts_on/ends_on rollup from the
    // serializer). Painted on the group's row, even collapsed.
    const subIdsByParent = new Map()
    const groupById = new Map()
    for (const g of groups) {
      groupById.set(g.id, g)
      if (g.parent_id) {
        if (!subIdsByParent.has(g.parent_id)) subIdsByParent.set(g.parent_id, [])
        subIdsByParent.get(g.parent_id).push(g.id)
      }
    }
    const summaryBars = []
    for (const r of rows) {
      if (r.kind !== 'group') continue
      const groupIds = new Set([r.id, ...(subIdsByParent.get(r.id) || [])])
      let minX = Infinity
      let maxX = -Infinity
      let isCritical = false
      for (const [, p] of posByItemId) {
        if (!groupIds.has(p.groupId)) continue
        minX = Math.min(minX, p.x)
        maxX = Math.max(maxX, p.x + p.width)
        if (p.critical) isCritical = true
      }
      if (minX === Infinity && windowStart) {
        const g = groupById.get(r.id)
        if (g && g.starts_on && g.ends_on) {
          minX = dateToX(g.starts_on, windowStart, pxPerDay)
          maxX = minX + durationDays(g.starts_on, g.ends_on) * pxPerDay
        }
      }
      if (minX === Infinity) continue
      summaryBars.push({
        id: r.id,
        rowIndex: r.rowIndex,
        x: minX,
        width: Math.max(6, maxX - minX),
        critical: isCritical
      })
    }

    return { rows, nodes, edges, summaryBars, rowCount: rows.length }
    // `collapsedIds` (Set) gets a new reference on every toggle →
    // `collapsedKey` (sorted-join string) is the stable proxy. Color-by does
    // not live here: it is applied on the bar (TaskBarNode), so it is not an
    // input of the model.
  }, [groups, items, dependencies, windowStart, pxPerDay, criticalKey, collapsedKey, search, filterStatus])
}
