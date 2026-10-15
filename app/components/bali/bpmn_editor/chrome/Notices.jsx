import Icon from './icons.jsx'

const TONE = { error: 'alert-error', warning: 'alert-warning', info: 'alert-info', success: 'alert-success', block: 'alert-error' }

// Blocking messages ("the connection breaks…") and short confirmations, at
// the bottom of the canvas where the eye already is.
export default function Notices ({ notices, onDismiss, t }) {
  if (!notices.length) return null
  return (
    <div className='bpmn-chrome pointer-events-none absolute inset-x-0 bottom-14 z-20 flex flex-col items-center gap-2 px-4'>
      {notices.map((n) => (
        <div key={n.id} role={n.tone === 'block' || n.tone === 'error' ? 'alert' : 'status'} className={`alert ${TONE[n.tone] || 'alert-info'} pointer-events-auto max-w-xl py-2 text-sm shadow-md`} data-testid='bpmn-notice'>
          <Icon name={n.tone === 'block' || n.tone === 'error' ? 'alertCircle' : 'info'} size={16} />
          <span>{n.text}</span>
          <button type='button' className='btn btn-ghost btn-xs btn-square' onClick={() => onDismiss(n.id)} aria-label={t('close')}>
            <Icon name='x' size={13} />
          </button>
        </div>
      ))}
    </div>
  )
}

export function HelpBar ({ text }) {
  return (
    <div className='bpmn-chrome pointer-events-none absolute inset-x-0 bottom-3 z-10 hidden justify-center px-40 xl:flex'>
      <p className='flex max-w-2xl items-center gap-2 rounded-full border border-base-300 bg-base-100 px-3 py-1 text-xs text-base-content/70 shadow-sm'>
        <Icon name='info' size={13} />{text}
      </p>
    </div>
  )
}
