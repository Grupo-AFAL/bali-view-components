import Dialog from './Dialog.jsx'

// The rules the editor checks for this host: on or off, their severity and
// where each comes from.
export default function RulesDialog ({ t, rules, onClose }) {
  return (
    <Dialog title={t('rules_title')} icon='listChecks' onClose={onClose} t={t} testId='bpmn-rules-dialog'>
      <p className='mb-3 text-sm text-base-content/70'>{t('rules_intro')}</p>
      <table className='table table-sm'>
        <tbody>
          {rules.map((rule) => (
            <tr key={rule.id} className={rule.on ? '' : 'opacity-50'}>
              <td className='font-mono text-xs'>{rule.id}</td>
              <td>
                <span className='block text-sm'>{rule.title || t(`rule_title_${rule.id}`)}</span>
                {rule.source && <span className='block text-xs text-base-content/60'>{t('rules_source')}: {rule.source}</span>}
              </td>
              <td className='text-right'>
                {rule.on
                  ? <span className={`badge badge-sm ${rule.severity === 'error' ? 'badge-error' : 'badge-warning'}`}>{t(`severity_${rule.severity}`)}</span>
                  : <span className='badge badge-ghost badge-sm'>—</span>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </Dialog>
  )
}
