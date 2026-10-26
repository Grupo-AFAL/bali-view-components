// The longest label the app may give it. Mirror Bali::BpmnEditor::Component::BADGE_TOGGLE_MAX.
export const BADGE_TOGGLE_MAX = 32

// The app's label (`badge_toggle: "Show status"`), read as defensively as
// the server validated it, else the i18n one.
export function badgeToggleLabel (t, label) {
  const own = typeof label === 'string' ? label.trim().slice(0, BADGE_TOGGLE_MAX) : ''
  return own || t('badges_toggle')
}

// «Show badges»: shows and hides the lanes' and nodes' `appearance.badge`. A checkbox
// with role="switch", named by its own label — which a narrow canvas hides
// from the eye only (`.bpmn-tool-label`, flow.css), leaving it as the title.
export default function BadgeSwitch ({ t, label, visible, onToggle, className = '' }) {
  const text = badgeToggleLabel(t, label)
  return (
    <label className={`bpmn-badge-switch flex cursor-pointer items-center gap-1.5 text-xs ${className}`} title={text}>
      <input type='checkbox' role='switch' className='toggle toggle-xs' checked={visible} onChange={onToggle} data-testid='bpmn-badge-toggle' />
      <span className='bpmn-tool-label'>{text}</span>
    </label>
  )
}
