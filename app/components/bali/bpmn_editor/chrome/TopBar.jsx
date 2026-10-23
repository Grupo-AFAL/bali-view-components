import Icon from './icons.jsx'

const STATUS = {
  saved: { key: 'save_saved', icon: 'save', className: 'text-base-content/70' },
  dirty: { key: 'save_dirty', icon: 'alertCircle', className: 'text-warning' },
  saving: { key: 'save_saving', icon: 'refresh', className: 'text-base-content/70' },
  error: { key: 'save_error', icon: 'alertCircle', className: 'text-error' },
  finalized: { key: 'save_finalized', icon: 'check', className: 'text-success' }
}

function IconButton ({ icon, label, shortcut, onClick, disabled }) {
  return (
    <button
      type='button' className='btn btn-ghost btn-sm btn-square' onClick={onClick} disabled={disabled}
      aria-label={label} title={shortcut ? `${label} (${shortcut})` : label}
    >
      <Icon name={icon} size={16} />
    </button>
  )
}

// The editor's own bar: what the host says about the document, whether the
// draft is saved, the pending issues, history, exports and the save /
// finalize actions. Page title, "edit mode" and "exit" belong to the host.
export default function TopBar ({
  t, editable, notesOnly = false, statusLabel, saveStatus, autosave, issues, onIssues, onRules, history, onSave, onFinalize, canFinalize,
  finalizing, exports, onCompare, comparing
}) {
  const status = STATUS[saveStatus] || STATUS.saved
  const errors = issues.filter((i) => i.severity === 'error').length
  return (
    <div className='bpmn-chrome flex flex-wrap items-center gap-x-3 gap-y-2 border-b border-base-300 bg-base-100 px-3 py-2'>
      {statusLabel && <span className='badge badge-ghost badge-sm whitespace-nowrap'>{statusLabel}</span>}
      {editable
        ? (
          <span className={`flex items-center gap-1 text-xs ${status.className}`} role='status' aria-live='polite' data-testid='bpmn-save-status'>
            <Icon name={status.icon} size={13} className={saveStatus === 'saving' ? 'animate-spin' : ''} />{t(status.key)}
          </span>
          )
        : <span className='badge badge-sm'>{t('read_only')}</span>}
      {notesOnly && (
        // Read-only with notes (Component `annotatable:`): the notes' own save.
        <span className={`flex items-center gap-1 text-xs ${status.className}`} role='status' aria-live='polite' data-testid='bpmn-save-status'>
          <Icon name={status.icon} size={13} className={saveStatus === 'saving' ? 'animate-spin' : ''} />{t(saveStatus === 'saved' ? 'notes_saved' : status.key)}
        </span>
      )}
      {editable && issues.length > 0 && (
        <button
          type='button'
          className={`btn btn-xs gap-1 ${errors ? 'btn-warning' : 'btn-ghost border-base-300'}`}
          onClick={onIssues}
          data-testid='bpmn-pending-button'
        >
          <Icon name='alert' size={13} />{t.count('pending', issues.length)}
        </button>
      )}
      {editable && onRules && (
        <button type='button' className='btn btn-ghost btn-xs gap-1' onClick={onRules}>
          <Icon name='listChecks' size={13} />{t('rules_button')}
        </button>
      )}
      {onCompare && (
        <button type='button' className={`btn btn-ghost btn-xs gap-1 ${comparing ? 'btn-active' : ''}`} onClick={onCompare} aria-pressed={String(Boolean(comparing))} data-testid='bpmn-compare-button'>
          <Icon name='compare' size={13} />{t('compare')}
        </button>
      )}
      <span className='grow' />
      {editable && (
        <div className='flex items-center' role='group'>
          <IconButton icon='undo' label={t('undo')} shortcut='Ctrl+Z' onClick={history.undo} disabled={!history.canUndo} />
          <IconButton icon='redo' label={t('redo')} shortcut='Ctrl+Y' onClick={history.redo} disabled={!history.canRedo} />
        </div>
      )}
      {exports && (
        <div className='flex items-center' role='group'>
          <IconButton icon='download' label={t('download_bpmn')} onClick={exports.bpmn} />
          <IconButton icon='image' label={t('download_image')} onClick={exports.png} />
          <IconButton icon='note' label={t('download_svg')} onClick={exports.svg} />
          <IconButton icon='printer' label={t('print')} onClick={exports.print} />
        </div>
      )}
      {editable && (
        <>
          {autosave && (
            <span className='hidden items-center gap-1 text-xs text-base-content/60 lg:flex'>
              <Icon name='refresh' size={12} />{t('autosave')}
            </span>
          )}
          <button type='button' className='btn btn-outline btn-sm gap-1' onClick={onSave} disabled={saveStatus === 'saving'}>
            <Icon name='save' size={14} />{t('save_draft')}
          </button>
          {canFinalize && (
            <button type='button' className='btn btn-success btn-sm gap-1' onClick={onFinalize} disabled={finalizing} data-testid='bpmn-finalize'>
              <Icon name='flag' size={14} />{t('finalize')}
            </button>
          )}
        </>
      )}
    </div>
  )
}
