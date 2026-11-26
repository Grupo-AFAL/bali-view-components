import Icon from './icons.jsx'

// One pending issue as the pending panel and the properties panel both write
// it: the severity's icon, the message, the rule's id, and whether the server
// found it.
export default function IssueLine ({ issue, t, size = 15 }) {
  const error = issue.severity === 'error'
  return (
    <>
      <Icon name={error ? 'alertCircle' : 'alert'} size={size} className={`mt-0.5 flex-none ${error ? 'text-error' : 'text-warning'}`} />
      <span className='grow'>{issue.message}</span>
      <span className='badge badge-ghost badge-sm font-mono'>{issue.rule}</span>
      {issue.source === 'server' && <span className='badge badge-outline badge-sm'>{t('pending_server')}</span>}
    </>
  )
}
