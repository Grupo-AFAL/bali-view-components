import { useEffect } from 'react'

// The editor the user touched last. Keyboard shortcuts go to it while the
// focus is inside it or nowhere (on <body>, where it lands when the focused
// node is deleted) — with several editors on a page, only that one answers.
let activeEditor = null

export const claimKeyboard = (wrapper) => { activeEditor = wrapper }

export default function useKeyboard (wrapperRef, onKeyDown) {
  useEffect(() => {
    const onDocumentKey = (event) => {
      const wrapper = wrapperRef.current
      if (!wrapper) return
      const focus = document.activeElement
      const inside = focus && wrapper.contains(focus)
      if (inside || ((!focus || focus === document.body) && activeEditor === wrapper)) onKeyDown(event)
    }
    // A click anywhere else on the page hands the keyboard back to the page.
    const onDocumentPointer = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target) && activeEditor === wrapperRef.current) activeEditor = null
    }
    document.addEventListener('keydown', onDocumentKey)
    document.addEventListener('pointerdown', onDocumentPointer, true)
    return () => {
      document.removeEventListener('keydown', onDocumentKey)
      document.removeEventListener('pointerdown', onDocumentPointer, true)
    }
  }, [wrapperRef, onKeyDown])
}
