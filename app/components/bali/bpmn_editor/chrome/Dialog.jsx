import { useEffect, useRef } from 'react'
import Icon from './icons.jsx'

// A dialog drawn inside the editor rather than on the page, so it still shows
// when the editor is in full screen (only the full-screen element is painted).
export default function Dialog ({ title, icon, onClose, children, footer, t, testId }) {
  const ref = useRef(null)
  useEffect(() => {
    const previous = document.activeElement
    ref.current && ref.current.focus()
    return () => { if (previous && previous.focus) previous.focus({ preventScroll: true }) }
  }, [])
  return (
    <div className='bpmn-chrome absolute inset-0 z-30 flex items-center justify-center bg-base-content/30 p-4' onPointerDown={(e) => { if (e.target === e.currentTarget) onClose() }}>
      <div
        ref={ref} role='dialog' aria-modal='true' aria-label={title} tabIndex={-1} data-testid={testId}
        className='flex max-h-full w-full max-w-2xl flex-col rounded-xl bg-base-100 shadow-xl outline-none'
        onKeyDown={(e) => { if (e.key === 'Escape') { e.stopPropagation(); onClose() } }}
      >
        <div className='flex items-center gap-2 border-b border-base-300 px-4 py-3'>
          {icon && <Icon name={icon} size={18} />}
          <h2 className='grow text-base font-semibold'>{title}</h2>
          <button type='button' className='btn btn-ghost btn-sm btn-square' onClick={onClose} aria-label={t('close')}><Icon name='x' size={16} /></button>
        </div>
        <div className='overflow-y-auto px-4 py-3'>{children}</div>
        {footer && <div className='flex justify-end gap-2 border-t border-base-300 px-4 py-3'>{footer}</div>}
      </div>
    </div>
  )
}
