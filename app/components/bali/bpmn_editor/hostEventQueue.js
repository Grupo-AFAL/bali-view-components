// The requests an app may send whenever its own code runs — on its connect,
// before the island's bundle has loaded, or between the island's first commit
// and the effect that starts listening (hooks/useHostEvents.js). Kept by the
// Stimulus controller from its connect, in order, until the island takes
// them; after that the island's own listener receives them. Only the ones
// that set state: a reload or a drawer's answer cannot come before the island.
export const QUEUED_HOST_EVENTS = ['bali-bpmn:select', 'bali-bpmn:badges', 'bali-bpmn:compare']

export function hostEventQueue (element) {
  let queue = []
  let taken = false
  const listener = (event) => { if (!taken && event.target === element) queue.push(event) }
  for (const name of QUEUED_HOST_EVENTS) element.addEventListener(name, listener)
  return {
    take () {
      taken = true
      const events = queue
      queue = []
      return events
    },
    stop () {
      for (const name of QUEUED_HOST_EVENTS) element.removeEventListener(name, listener)
    }
  }
}
