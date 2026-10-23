import { sourceText } from '../model/rules/engine.js'
import Dialog from './Dialog.jsx'

// The chapters of the criteria matrix, in its order; the host's own rules last.
const SECTIONS = [
  'lanes', 'external', 'activities', 'start_events', 'intermediate_events', 'end_events', 'gateways',
  'decisions', 'sequence_flows', 'subprocesses', 'artifacts', 'structure', 'layout', 'app'
]

// The rules the editor checks for this host, grouped by chapter: on or off,
// their severity, the criteria they cover and where each comes from.
export default function RulesDialog ({ t, rules, onClose }) {
  const groups = SECTIONS.map((section) => [section, rules.filter((rule) => (SECTIONS.includes(rule.section) ? rule.section : 'app') === section)])
    .filter(([, list]) => list.length)
  return (
    <Dialog title={t('rules_title')} icon='listChecks' onClose={onClose} t={t} testId='bpmn-rules-dialog'>
      <p className='mb-3 text-sm text-base-content/70'>{t('rules_intro')}</p>
      {groups.map(([section, list]) => (
        <section key={section} className='mb-4' data-section={section}>
          <h3 className='mb-1 text-xs font-semibold uppercase tracking-wide text-base-content/60'>{t(`rules_section_${section}`)}</h3>
          <table className='table table-sm'>
            <tbody>
              {list.map((rule) => (
                <tr key={rule.id} className={rule.on ? '' : 'opacity-50'} data-rule={rule.id}>
                  <td className='w-16 font-mono text-xs'>{rule.id}</td>
                  <td>
                    <span className='block text-sm'>{rule.title || t(`rule_title_${rule.id}`)}</span>
                    {rule.criteria && rule.criteria.length > 0 && (
                      <span className='block text-xs text-base-content/60'>{t('rules_criteria')}: <span className='font-mono'>{rule.criteria.join(', ')}</span></span>
                    )}
                    {rule.source && <span className='block text-xs text-base-content/60'>{t('rules_source')}: {sourceText(rule.source, t)}</span>}
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
        </section>
      ))}
    </Dialog>
  )
}
