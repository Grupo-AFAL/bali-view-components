import { useEffect, useState } from 'react'
import { remoteSearch } from './remoteSearch.js'

// One host-defined field (node_fields / lane_fields). Options are local
// (`options: [{ value, label }]`) or remote (`url`, queried with ?q=).
export default function FieldInput ({ field, value, onChange, disabled, t }) {
  const [remote, setRemote] = useState(null)
  const needsOptions = field.type === 'select' || field.type === 'multi_select'
  useEffect(() => {
    if (!needsOptions || !field.url) return
    let live = true
    remoteSearch(field.url, {}).then((items) => {
      if (live) setRemote(items.map((i) => ({ value: String(i.id ?? i.value), label: i.label })))
    })
    return () => { live = false }
  }, [needsOptions, field.url])
  const options = (remote || field.options || []).map((o) => (typeof o === 'object' ? { value: String(o.value ?? o.id), label: o.label ?? String(o.value) } : { value: String(o), label: String(o) }))

  switch (field.type) {
    case 'readonly':
      return <p className='whitespace-pre-line rounded bg-base-200 px-2 py-1 text-sm'>{value == null || value === '' ? '—' : String(value)}</p>
    case 'textarea':
      return <textarea className='textarea textarea-sm w-full' rows={3} value={value ?? ''} disabled={disabled} placeholder={field.placeholder} onChange={(e) => onChange(e.target.value)} />
    case 'number':
      return <input type='number' className='input input-sm w-full' value={value ?? ''} disabled={disabled} min={field.min} max={field.max} step={field.step} onChange={(e) => onChange(e.target.value === '' ? null : Number(e.target.value))} />
    case 'select':
      return (
        <select className='select select-sm w-full' value={value ?? ''} disabled={disabled} onChange={(e) => onChange(e.target.value || null)}>
          <option value=''>{t('props_select_placeholder')}</option>
          {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
        </select>
      )
    case 'multi_select': {
      const chosen = new Set((Array.isArray(value) ? value : []).map(String))
      return (
        <div className='flex flex-wrap gap-1'>
          {options.map((o) => (
            <label key={o.value} className={`badge cursor-pointer gap-1 ${chosen.has(o.value) ? 'badge-primary' : 'badge-ghost'}`}>
              <input type='checkbox' className='hidden' checked={chosen.has(o.value)} disabled={disabled}
                onChange={(e) => { const next = new Set(chosen); e.target.checked ? next.add(o.value) : next.delete(o.value); onChange([...next]) }} />
              {o.label}
            </label>
          ))}
        </div>
      )
    }
    default:
      return <input className='input input-sm w-full' value={value ?? ''} disabled={disabled} placeholder={field.placeholder} onChange={(e) => onChange(e.target.value)} />
  }
}
