// In a build with code splitting `import('tippy.js')` waits for a chunk, so the pointer or
// the focus can reach the reference before tippy listens. The `mouseenter` or `focusin` it
// waits for has already fired and does not fire again until the user leaves and comes back.
export function triggeredBeforeMount (reference, trigger) {
  const events = trigger.split(/\s+/)

  return (events.includes('mouseenter') && reference.matches(':hover')) ||
    (events.includes('focusin') && reference.matches(':focus-within'))
}
