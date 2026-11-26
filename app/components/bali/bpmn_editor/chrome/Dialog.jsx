import { useLayoutEffect, useRef } from 'react'
import Icon from './icons.jsx'

// `narrow` for a question of one line, `medium` for a list of sentences, `wide`
// for a table.
const SIZES = { narrow: 'max-w-md', medium: 'max-w-4xl', wide: 'max-w-5xl' }

// A native `<dialog>` opened with `showModal()`: the top layer puts it and its
// veil over the whole page, not only over the editor, and makes the rest inert.
// It stays inside the editor's root, so it still shows in the browser's full
// screen (the top layer paints only what the full-screen element contains).
//
// The `<dialog>` itself is the veil, as large as the viewport; the panel is its
// child, so a press on the veil is one whose target is the dialog.
export default function Dialog ({ title, icon, onClose, children, footer, t, testId, size = 'medium' }) {
  const dialog = useRef(null)
  const panel = useRef(null)
  // Before paint: a `<dialog>` that is not open yet would flash in the flow.
  useLayoutEffect(() => {
    const element = dialog.current
    const previous = document.activeElement
    if (element.showModal) element.showModal(); else element.setAttribute('open', '')
    panel.current.focus({ preventScroll: true })
    return () => {
      if (element.open && element.close) element.close()
      if (previous && previous.focus) previous.focus({ preventScroll: true })
    }
  }, [])
  return (
    <dialog
      ref={dialog} aria-label={title}
      className='bpmn-chrome bpmn-dialog fixed inset-0 m-0 flex h-full max-h-none w-full max-w-none items-center justify-center bg-black/50 p-3 text-base-content backdrop-blur-[1px] backdrop:bg-transparent sm:p-6'
      onPointerDown={(e) => { if (e.target === e.currentTarget) onClose() }}
      onCancel={(e) => { e.preventDefault(); onClose() }}
      onKeyDown={(e) => { if (e.key === 'Escape') { e.preventDefault(); e.stopPropagation(); onClose() } }}
    >
      <div
        ref={panel} tabIndex={-1} data-testid={testId}
        className={`flex max-h-full w-full ${SIZES[size]} flex-col rounded-box bg-base-100 shadow-2xl outline-none`}
      >
        <div className='flex flex-none items-center gap-2 border-b border-base-300 px-5 py-3'>
          {icon && <Icon name={icon} size={18} />}
          <h2 className='grow text-base font-semibold'>{title}</h2>
          <button type='button' className='btn btn-ghost btn-sm btn-square' onClick={onClose} aria-label={t('close')}><Icon name='x' size={16} /></button>
        </div>
        <div className='min-h-0 overflow-y-auto overscroll-contain px-5 py-4'>{children}</div>
        {footer && <div className='flex flex-none justify-end gap-2 border-t border-base-300 px-5 py-3'>{footer}</div>}
      </div>
    </dialog>
  )
}
