// The shape of a process as a graph of sequence flows, for the structure
// rules (rules.js): which connections loop back, which split each merge
// closes, which branches reach which element, where the cycles are.
//
// - Back edges come from a depth-first walk from the start events (then from
//   anything not reached): a connection to an element still on the walk's
//   stack returns to an earlier point of the flow — a rework loop.
// - Without the back edges the flow is acyclic; a merge's opening is its
//   immediate dominator there (Cooper, Harvey and Kennedy's iterative
//   algorithm): the last element every path to the merge goes through.
// - Cycles are Tarjan's strongly connected components over every connection.
import { isGateway } from './catalog.js'

export function flowStructure (ctx) {
  const ids = ctx.nodes.map((n) => String(n.id))
  const out = new Map(ids.map((id) => [id, []]))
  for (const e of ctx.flows) {
    if (out.has(String(e.source)) && out.has(String(e.target))) out.get(String(e.source)).push(e)
  }

  // Back edges.
  const back = new Set()
  const state = new Map()
  const walk = (root) => {
    const stack = [[root, 0]]
    state.set(root, 1)
    while (stack.length) {
      const top = stack[stack.length - 1]
      const edges = out.get(top[0])
      if (top[1] < edges.length) {
        const e = edges[top[1]++]
        const next = String(e.target)
        if (state.get(next) === 1) back.add(e)
        else if (!state.get(next)) { state.set(next, 1); stack.push([next, 0]) }
      } else {
        state.set(top[0], 2)
        stack.pop()
      }
    }
  }
  const starts = ctx.nodes.filter((n) => n.type === 'start_event').map((n) => String(n.id))
  for (const id of [...starts, ...ids]) if (!state.get(id)) walk(id)

  const forwardOut = new Map(ids.map((id) => [id, out.get(id).filter((e) => !back.has(e))]))
  const forwardIn = new Map(ids.map((id) => [id, []]))
  for (const [, edges] of forwardOut) for (const e of edges) forwardIn.get(String(e.target)).push(e)

  // Immediate dominators over the acyclic remainder, from a virtual root
  // joined to every element nothing forward reaches.
  const ROOT = '\u0000root'
  const order = []
  const seen = new Set()
  const post = (id) => {
    const stack = [[id, 0]]
    seen.add(id)
    while (stack.length) {
      const top = stack[stack.length - 1]
      const edges = forwardOut.get(top[0])
      if (top[1] < edges.length) {
        const next = String(edges[top[1]++].target)
        if (!seen.has(next)) { seen.add(next); stack.push([next, 0]) }
      } else {
        order.push(top[0])
        stack.pop()
      }
    }
  }
  const sources = ids.filter((id) => !forwardIn.get(id).length)
  for (const id of [...sources, ...ids]) if (!seen.has(id)) post(id)
  const rpo = [ROOT, ...order.reverse()]
  const index = new Map(rpo.map((id, i) => [id, i]))
  const preds = (id) => (forwardIn.get(id).length ? forwardIn.get(id).map((e) => String(e.source)) : [ROOT])
  const idom = new Map([[ROOT, ROOT]])
  const intersect = (a, b) => {
    while (a !== b) {
      while (index.get(a) > index.get(b)) a = idom.get(a)
      while (index.get(b) > index.get(a)) b = idom.get(b)
    }
    return a
  }
  for (let changed = true; changed;) {
    changed = false
    for (const id of rpo.slice(1)) {
      const done = preds(id).filter((p) => idom.has(p))
      if (!done.length) continue
      const next = done.slice(1).reduce((acc, p) => intersect(acc, p), done[0])
      if (idom.get(id) !== next) { idom.set(id, next); changed = true }
    }
  }

  // Everything forward-reachable from `id`, not going past `stop`.
  const reach = (id, stop = null) => {
    const found = new Set([id])
    const stack = [id]
    while (stack.length) {
      const current = stack.pop()
      if (current === stop) continue
      for (const e of forwardOut.get(current) || []) {
        const next = String(e.target)
        if (!found.has(next)) { found.add(next); stack.push(next) }
      }
    }
    return found
  }

  return {
    back,
    isBack: (edge) => back.has(edge),
    forwardOut: (node) => forwardOut.get(String(node.id)) || [],
    forwardIn: (node) => forwardIn.get(String(node.id)) || [],
    reach,
    // The split a merge closes: its immediate dominator when that is a
    // splitting gateway, else null (paths that meet without a common split).
    opening (node) {
      const dominator = idom.get(String(node.id))
      const split = dominator && dominator !== ROOT ? ctx.byId.get(dominator) : null
      return split && isGateway(split) && (forwardOut.get(dominator) || []).length > 1 ? split : null
    },
    cycles: () => stronglyConnected(ids, out)
  }
}

// Tarjan's algorithm, iterative; only components that are cycles.
function stronglyConnected (ids, out) {
  let counter = 0
  const index = new Map()
  const low = new Map()
  const onStack = new Set()
  const stack = []
  const components = []
  for (const root of ids) {
    if (index.has(root)) continue
    const work = [[root, 0]]
    index.set(root, counter); low.set(root, counter); counter++
    stack.push(root); onStack.add(root)
    while (work.length) {
      const top = work[work.length - 1]
      const [id] = top
      const edges = out.get(id)
      if (top[1] < edges.length) {
        const next = String(edges[top[1]++].target)
        if (!index.has(next)) {
          index.set(next, counter); low.set(next, counter); counter++
          stack.push(next); onStack.add(next)
          work.push([next, 0])
        } else if (onStack.has(next)) {
          low.set(id, Math.min(low.get(id), index.get(next)))
        }
      } else {
        work.pop()
        if (work.length) {
          const parent = work[work.length - 1][0]
          low.set(parent, Math.min(low.get(parent), low.get(id)))
        }
        if (low.get(id) === index.get(id)) {
          const component = []
          let member
          do { member = stack.pop(); onStack.delete(member); component.push(member) } while (member !== id)
          const selfLoop = out.get(id).some((e) => String(e.target) === id)
          if (component.length > 1 || selfLoop) components.push(component)
        }
      }
    }
  }
  return components
}
