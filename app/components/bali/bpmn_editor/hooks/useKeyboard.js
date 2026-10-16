import { useEffect } from 'react'

// The editor the user touched last. Keyboard shortcuts go to it while the
// focus is inside it or nowhere (on <body>, where it lands when the focused
// node is deleted) — with several editors on a page, only that one answers.
let activeEditor = null

export const claimKeyboard = (wrapper) => { activeEditor = wrapper }

export default function useKeyboard (wrapperRef, onKeyDown, onKeyUp = null) {
  useEffect(() => {
    const ours = () => {
      const wrapper = wrapperRef.current
      if (!wrapper) return false
      const focus = document.activeElement
      const inside = focus && wrapper.contains(focus)
      return inside || ((!focus || focus === document.body) && activeEditor === wrapper)
    }
    const onDocumentKey = (event) => { if (ours()) onKeyDown(event) }
    const onDocumentKeyUp = (event) => { if (onKeyUp && ours()) onKeyUp(event) }
    // A click anywhere else on the page hands the keyboard back to the page.
    const onDocumentPointer = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target) && activeEditor === wrapperRef.current) activeEditor = null
    }
    document.addEventListener('keydown', onDocumentKey)
    document.addEventListener('keyup', onDocumentKeyUp)
    document.addEventListener('pointerdown', onDocumentPointer, true)
    return () => {
      document.removeEventListener('keydown', onDocumentKey)
      document.removeEventListener('keyup', onDocumentKeyUp)
      document.removeEventListener('pointerdown', onDocumentPointer, true)
    }
  }, [wrapperRef, onKeyDown, onKeyUp])
}
