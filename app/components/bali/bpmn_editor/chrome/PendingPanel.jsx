import Dialog from './Dialog.jsx'
import Icon from './icons.jsx'

// "N pending": the issues grouped by severity. Picking one centres the canvas
// on its element and highlights it.
export default function PendingPanel ({ t, issues, onPick, onClose }) {
  const groups = [
    ['error', t('pending_errors'), t('pending_errors_hint'), 'text-error'],
    ['warning', t('pending_warnings'), t('pending_warnings_hint'), 'text-warning']
  ]
  return (
    <Dialog title={t('pending_title')} icon='alert' onClose={onClose} t={t} testId='bpmn-pending-panel'
      footer={<button type='button' className='btn btn-primary btn-sm' onClick={onClose}>{t('understood')}</button>}>
      <p className='mb-3 text-sm text-base-content/70'>{t('pending_intro')}</p>
      {groups.map(([severity, title, hint, tone]) => {
        const list = issues.filter((i) => i.severity === severity)
        return (
          <section key={severity} className='mb-4'>
            <h3 className='mb-1 flex items-center gap-2 text-sm font-semibold'>
              <span className={tone}>●</span>{title}
              <span className='font-normal text-base-content/60'>· {hint} · {list.length}</span>
            </h3>
            {list.length
              ? (
                <ul className='flex flex-col'>
                  {list.map((issue, i) => (
                    <li key={`${issue.rule}-${issue.element_id}-${i}`}>
                      <button
                        type='button'
                        className='flex w-full items-start gap-2 rounded px-2 py-1.5 text-left text-sm hover:bg-base-200 disabled:cursor-default'
                        disabled={!issue.element_id}
                        onClick={() => onPick(issue)}
                        data-rule={issue.rule}
                      >
                        <Icon name={severity === 'error' ? 'alertCircle' : 'alert'} size={15} className={`mt-0.5 ${tone}`} />
                        <span className='grow'>{issue.message}</span>
                        <span className='badge badge-ghost badge-sm font-mono'>{issue.rule}</span>
                        {issue.source === 'server' && <span className='badge badge-outline badge-sm'>{t('pending_server')}</span>}
                        {issue.element_id && <Icon name='chevronRight' size={13} className='mt-0.5 opacity-50' />}
                      </button>
                    </li>
                  ))}
                </ul>
                )
              : <p className='px-2 text-sm text-base-content/60'>{t('pending_none')}</p>}
          </section>
        )
      })}
    </Dialog>
  )
}
