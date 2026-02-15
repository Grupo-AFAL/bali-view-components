import { createReactInlineContentSpec } from '@blocknote/react'

// Default entity type display configuration.
// Host apps can override via the referencesConfig prop (from references_config: in Ruby).
// Colors use DaisyUI semantic names which are resolved to CSS vars at render time.
export const DEFAULT_ENTITY_TYPE_CONFIG = {
  task: { icon: '\u2610', label: 'Task', color: 'info' },
  project: { icon: '\u25C8', label: 'Project', color: 'accent' },
  document: { icon: '\u25E7', label: 'Document', color: 'success' },
  default: { icon: '#', label: '', color: 'secondary' }
}

// Module-level config ref that the static render function can access.
// Updated by useEntityReferences when referencesConfig prop is provided.
let activeEntityConfig = DEFAULT_ENTITY_TYPE_CONFIG

export function setActiveEntityConfig (config) {
  activeEntityConfig = config
}

export function getActiveEntityConfig () {
  return activeEntityConfig
}

// Resolve a color name to a CSS variable reference.
// Accepts DaisyUI names ('info'), full var() refs, hex, or rgb values.
export const resolveColor = (color) => {
  if (!color) return undefined
  if (color.startsWith('var(') || color.startsWith('#') || color.startsWith('rgb')) return color
  return `var(--color-${color})`
}

// Mention inline content - renders as a styled chip with @ prefix
export const Mention = createReactInlineContentSpec(
  {
    type: 'mention',
    propSchema: {
      user: { default: '' },
      id: { default: '' }
    },
    content: 'none'
  },
  {
    render: (props) => (
      <span className='bn-mention' data-mention-id={props.inlineContent.props.id}>
        @{props.inlineContent.props.user}
      </span>
    )
  }
)

// Entity reference inline content - renders as a styled chip with type icon and label
export const EntityReference = createReactInlineContentSpec(
  {
    type: 'entityReference',
    propSchema: {
      entityType: { default: '' },
      entityId: { default: '' },
      entityName: { default: '' },
      url: { default: '' }
    },
    content: 'none'
  },
  {
    render: (props) => {
      const { entityType, entityName, url, entityId } = props.inlineContent.props
      const config = activeEntityConfig[entityType] || activeEntityConfig.default
      const display = entityName || `${entityType}:${entityId}`
      const typeLabel = config.label || (entityType ? entityType.charAt(0).toUpperCase() + entityType.slice(1) : '')
      const chip = (
        <span
          className='bn-entity-reference'
          data-entity-type={entityType}
          data-entity-id={entityId}
          style={config.color ? { '--entity-ref-color': resolveColor(config.color) } : undefined}
        >
          <span className='bn-entity-reference-icon'>{config.icon}</span>
          {typeLabel && <span className='bn-entity-reference-label'>{typeLabel}</span>}
          {display}
        </span>
      )

      if (url) {
        return <a href={url} className='bn-entity-reference-link'>{chip}</a>
      }
      return chip
    }
  }
)
