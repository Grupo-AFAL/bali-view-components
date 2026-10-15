import Icon from './icons.jsx'

// Review notes of one element: numbered markers on the canvas, the text and
// a tag here. The tags are the host's (`annotation_tags:`).
export default function NotesEditor ({ t, notes, tags, editable, onAdd, onChange, onDelete }) {
  return (
    <section className='flex flex-col gap-2'>
      <div className='flex items-center justify-between'>
        <span className='text-xs font-semibold text-base-content/70'>{t('notes_title')}</span>
        {editable && (
          <button type='button' className='btn btn-ghost btn-xs gap-1' onClick={onAdd}>
            <Icon name='plus' size={12} />{t('notes_add')}
          </button>
        )}
      </div>
      {!notes.length && <p className='text-xs text-base-content/60'>{t('notes_empty')}</p>}
      {notes.map((note) => (
        <div key={note.id} className='flex flex-col gap-1 rounded border border-base-300 p-2'>
          <div className='flex items-center gap-2'>
            <span className='bpmn-note-number' style={{ '--bpmn-note-color': (tags.find((tag) => tag.key === note.tag) || {}).color }}>{note.number}</span>
            {tags.length > 0 && (
              <select className='select select-xs grow' value={note.tag || ''} disabled={!editable} aria-label={t('notes_tag')} onChange={(e) => onChange(note.id, { tag: e.target.value || null })}>
                <option value=''>{t('notes_none_tag')}</option>
                {tags.map((tag) => <option key={tag.key} value={tag.key}>{tag.label}</option>)}
              </select>
            )}
            {editable && (
              <button type='button' className='btn btn-ghost btn-xs btn-square ml-auto' onClick={() => onDelete(note.id)} aria-label={t('delete')}>
                <Icon name='trash' size={12} />
              </button>
            )}
          </div>
          <textarea className='textarea textarea-xs w-full' rows={2} value={note.text || ''} disabled={!editable} aria-label={t('notes_text')}
            onChange={(e) => onChange(note.id, { text: e.target.value }, `note:${note.id}`)} />
        </div>
      ))}
    </section>
  )
}
