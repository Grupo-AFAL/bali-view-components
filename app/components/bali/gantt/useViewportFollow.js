// Makes a chrome layer follow the React Flow pan WITHOUT re-rendering it.
//
// The layers that sit outside the pane (time header, grid + weekend bands,
// row bands, group summary bars, today line, left table) are positioned in
// canvas coordinates and shifted as a block by the viewport transform. Only
// the WRAPPER div uses that transform — its hundreds of children (ticks,
// rows, bars) do not depend on it at all. Subscribing with `useStore` made
// every one of those layers re-render its whole child list once per pan
// frame; subscribing to the store imperatively and writing `style.transform`
// on a ref costs ZERO React renders per frame instead, which is the whole
// point of this hook.
//
// The transform is deliberately absent from the element's `style` prop: React
// only writes the style keys it knows about, so it never fights the value
// written here.
//
// Must be used inside <ReactFlowProvider> (it reads the flow store).
import { useCallback, useLayoutEffect, useRef } from 'react'
import { useStoreApi } from '@xyflow/react'

// `axis` picks which translations the layer follows: 'x' (time axis), 'y'
// (rows) or 'xy'. `offsetX` is a fixed canvas offset added to the horizontal
// translation (the today line lives at a fixed x of the canvas).
export function useViewportFollow (axis, offsetX = 0) {
  const store = useStoreApi()
  const ref = useRef(null)

  const write = useCallback(
    ([x, y]) => {
      const el = ref.current
      if (!el) return
      if (axis === 'y') el.style.transform = `translateY(${y}px)`
      else if (axis === 'x') el.style.transform = `translateX(${x + offsetX}px)`
      else el.style.transform = `translate(${x}px, ${y}px)`
    },
    [axis, offsetX]
  )

  // On every render (mount included, and after a layer that returned null
  // starts rendering) put the CURRENT transform on the element: the
  // subscription below only fires on later changes.
  useLayoutEffect(() => write(store.getState().transform))

  useLayoutEffect(() => {
    // The flow store is a plain zustand store: `subscribe` takes no selector,
    // so the listener runs on every store change and compares the transform
    // tuple by reference itself (React Flow replaces the array on each pan).
    let previous = store.getState().transform
    return store.subscribe((state) => {
      if (state.transform === previous) return
      previous = state.transform
      write(state.transform)
    })
  }, [store, write])

  return ref
}
