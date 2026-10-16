import { createContext, useCallback, useContext, useEffect, useId, useState } from 'react'
import { createPortal } from 'react-dom'

// The palette's tooltips (and the quick menu's "More"): a name, what the
// element is and when to use it. Portaled into the editor's root rather than
// drawn inside the scrolling palette — a CSS tooltip inside a scroll container
// is clipped, or gives it a horizontal scrollbar (.claude/CLAUDE.md, «DaisyUI
// Tooltip Gotcha», #1392). Inside the editor's root it keeps the page's theme
// and shows in full screen.
const HintContext = createContext(null)
const GAP = 8
const WIDTH = 280 // w-70 in flow.css

export function HintLayer ({ rootRef, children }) {
  const [hint, setHint] = useState(null) // { id, rect, content }
  const show = useCallback((element, id, content) => setHint({ id, rect: element.getBoundingClientRect(), content }), [])
  const hide = useCallback((id) => setHint((current) => (current && current.id === id ? null : current)), [])

  // A scroll or a resize moves the trigger away from where the tooltip is.
  useEffect(() => {
    if (!hint) return undefined
    const drop = () => setHint(null)
    window.addEventListener('scroll', drop, true)
    window.addEventListener('resize', drop)
    return () => { window.removeEventListener('scroll', drop, true); window.removeEventListener('resize', drop) }
  }, [hint])

  const root = rootRef.current
  let position = null
  if (hint) {
    const { rect } = hint
    const right = rect.right + GAP + WIDTH <= window.innerWidth
    position = { left: right ? rect.right + GAP : Math.max(GAP, rect.left - GAP - WIDTH), top: Math.max(GAP, Math.min(rect.top, window.innerHeight - 160)) }
  }
  return (
    <HintContext.Provider value={{ show, hide, current: hint && hint.id }}>
      {children}
      {hint && root && createPortal(
        <div id={hint.id} role='tooltip' className='bpmn-hint' data-testid='bpmn-hint' style={position}>{hint.content}</div>,
        root
      )}
    </HintContext.Provider>
  )
}

// Render prop: `children(props)` gets the handlers and aria-describedby for
// the trigger. Without a HintLayer above it, nothing is added.
export function Hint ({ content, children }) {
  const context = useContext(HintContext)
  const id = `bpmn-hint-${useId().replace(/:/g, '')}`
  if (!context || !content) return children({})
  return children({
    onMouseEnter: (event) => context.show(event.currentTarget, id, content),
    onMouseLeave: () => context.hide(id),
    onFocus: (event) => context.show(event.currentTarget, id, content),
    onBlur: () => context.hide(id),
    'aria-describedby': context.current === id ? id : undefined
  })
}

// What a palette item's tooltip says: its name, what it is, when to use it,
// and the note the app put on it.
export function PaletteHint ({ t, itemKey, note }) {
  const text = (suffix) => {
    const key = `palette_${itemKey}_${suffix}`
    return t.has && t.has(key) ? t(key) : null
  }
  return (
    <>
      <p className='font-semibold'>{t(`palette_${itemKey}`)}</p>
      {text('summary') && <p className='mt-1'>{text('summary')}</p>}
      {text('when') && <p className='mt-1 text-base-content/70'>{text('when')}</p>}
      {note && <p className='mt-1 border-t border-base-300 pt-1 text-base-content/80'>{note}</p>}
    </>
  )
}
