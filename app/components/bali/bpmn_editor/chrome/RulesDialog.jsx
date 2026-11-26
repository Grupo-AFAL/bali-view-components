import { sourceText } from '../model/rules/engine.js'
import Dialog from './Dialog.jsx'

// The chapters of the criteria matrix, in its order; the host's own rules last.
const SECTIONS = [
  'lanes', 'external', 'activities', 'start_events', 'intermediate_events', 'end_events', 'gateways',
  'decisions', 'sequence_flows', 'subprocesses', 'artifacts', 'structure', 'layout', 'app'
]

// The rules the editor checks for this host, grouped by chapter: on or off,
// their severity, the criteria they cover and where each comes from. One table
// for every chapter, so the columns line up down the whole list; below `md`
// the criteria and the source go under the rule's title instead of beside it.
export default function RulesDialog ({ t, rules, onClose }) {
  const groups = SECTIONS.map((section) => [section, rules.filter((rule) => (SECTIONS.includes(rule.section) ? rule.section : 'app') === section)])
    .filter(([, list]) => list.length)
  return (
    <Dialog title={t('rules_title')} icon='listChecks' onClose={onClose} t={t} testId='bpmn-rules-dialog' size='wide'>
      <p className='mb-3 text-sm text-base-content/70'>{t('rules_intro')}</p>
      <table className='table table-sm'>
        <thead className='sticky -top-4 z-10 hidden bg-base-100 md:table-header-group'>
          <tr>
            <th className='w-20'>{t('rules_id')}</th>
            <th>{t('rules_rule')}</th>
            <th className='w-44'>{t('rules_criteria')}</th>
            <th className='w-72'>{t('rules_source')}</th>
            <th className='w-28 text-right'>{t('rules_severity')}</th>
          </tr>
        </thead>
        {groups.map(([section, list]) => (
          <tbody key={section} data-section={section}>
            <tr>
              <th colSpan={5} scope='colgroup' className='bg-base-200 text-xs font-semibold uppercase tracking-wide text-base-content/70'>
                {t(`rules_section_${section}`)}
              </th>
            </tr>
            {list.map((rule) => {
              const criteria = rule.criteria && rule.criteria.length > 0 ? rule.criteria.join(', ') : ''
              const source = rule.source ? sourceText(rule.source, t) : ''
              return (
                <tr key={rule.id} className={rule.on ? '' : 'opacity-50'} data-rule={rule.id}>
                  <td className='w-20 align-top font-mono text-xs'>{rule.id}</td>
                  <td className='align-top'>
                    <span className='block text-sm'>{rule.title || t(`rule_title_${rule.id}`)}</span>
                    {criteria && <span className='block text-xs text-base-content/60 md:hidden'>{t('rules_criteria')}: <span className='font-mono'>{criteria}</span></span>}
                    {source && <span className='block text-xs text-base-content/60 md:hidden'>{t('rules_source')}: {source}</span>}
                  </td>
                  <td className='hidden align-top font-mono text-xs text-base-content/70 md:table-cell'>{criteria}</td>
                  <td className='hidden align-top text-xs text-base-content/70 md:table-cell'>{source}</td>
                  <td className='align-top text-right'>
                    {rule.on
                      ? <span className={`badge badge-sm ${rule.severity === 'error' ? 'badge-error' : 'badge-warning'}`}>{t(`severity_${rule.severity}`)}</span>
                      : <span className='badge badge-ghost badge-sm'>{t('rules_off')}</span>}
                  </td>
                </tr>
              )
            })}
          </tbody>
        ))}
      </table>
    </Dialog>
  )
}
