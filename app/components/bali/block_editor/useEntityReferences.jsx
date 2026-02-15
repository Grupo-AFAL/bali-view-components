import { useCallback, useEffect, useMemo } from 'react'
import {
  DEFAULT_ENTITY_TYPE_CONFIG,
  setActiveEntityConfig,
  getActiveEntityConfig,
  resolveColor
} from './inlineContent'

export function useEntityReferences (editor, { referencesUrl, referencesResolveUrl, referencesConfig }) {
  // Merge host-provided entity type config with defaults
  useMemo(() => {
    if (!referencesConfig || Object.keys(referencesConfig).length === 0) {
      setActiveEntityConfig(DEFAULT_ENTITY_TYPE_CONFIG)
      return
    }
    const merged = { ...DEFAULT_ENTITY_TYPE_CONFIG }
    for (const [type, overrides] of Object.entries(referencesConfig)) {
      merged[type] = { ...(DEFAULT_ENTITY_TYPE_CONFIG[type] || DEFAULT_ENTITY_TYPE_CONFIG.default), ...overrides }
    }
    setActiveEntityConfig(merged)
  }, [referencesConfig])

  // Fetch entity reference suggestions from server
  const getEntityReferenceItems = useCallback(async (query) => {
    if (!referencesUrl) return []

    try {
      const url = new URL(referencesUrl, window.location.origin)
      if (query) url.searchParams.set('q', query)
      const response = await fetch(url, {
        headers: { Accept: 'application/json' }
      })
      if (!response.ok) return []
      const refs = await response.json()
      const activeConfig = getActiveEntityConfig()

      return refs.map((ref) => {
        const config = activeConfig[ref.entityType] || activeConfig.default
        const color = resolveColor(config.color)
        return {
          title: ref.entityName,
          group: config.label || ref.entityType,
          icon: (
            <span
              style={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                backgroundColor: color,
                display: 'inline-block',
                flexShrink: 0
              }}
            />
          ),
          badge: config.icon,
          onItemClick: () => {
            editor.insertInlineContent([
              {
                type: 'entityReference',
                props: {
                  entityType: ref.entityType,
                  entityId: String(ref.entityId),
                  entityName: ref.entityName
                }
              },
              ' '
            ])
          }
        }
      })
    } catch (error) {
      console.error('BlockEditor: Failed to fetch entity references:', error)
      return []
    }
  }, [editor, referencesUrl])

  // Resolve entity reference display names on document load
  useEffect(() => {
    if (!referencesResolveUrl || !editor) return

    const resolveEntityReferences = async () => {
      // Collect all entity reference nodes from the document
      const refs = []
      const collectRefs = (blocks) => {
        for (const block of blocks) {
          if (Array.isArray(block.content)) {
            for (const inline of block.content) {
              if (inline.type === 'entityReference' && inline.props?.entityId) {
                refs.push({
                  entityType: inline.props.entityType,
                  entityId: inline.props.entityId
                })
              }
            }
          }
          // Handle table content structure
          if (block.content?.type === 'tableContent') {
            for (const row of block.content.rows) {
              for (const cell of row.cells) {
                for (const inline of (cell.content || cell)) {
                  if (inline.type === 'entityReference' && inline.props?.entityId) {
                    refs.push({
                      entityType: inline.props.entityType,
                      entityId: inline.props.entityId
                    })
                  }
                }
              }
            }
          }
          if (block.children) collectRefs(block.children)
        }
      }

      collectRefs(editor.document)
      if (refs.length === 0) return

      // Deduplicate by entityType:entityId
      const uniqueRefs = Array.from(
        new Map(refs.map(r => [`${r.entityType}:${r.entityId}`, r])).values()
      )

      try {
        const csrfMeta = document.querySelector('meta[name="csrf-token"]')
        const response = await fetch(referencesResolveUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            ...(csrfMeta ? { 'X-CSRF-Token': csrfMeta.content } : {})
          },
          body: JSON.stringify({ refs: uniqueRefs })
        })

        if (!response.ok) return
        const resolved = await response.json()

        // Build lookup map
        const resolvedMap = new Map(
          resolved.map(r => [`${r.entityType}:${r.entityId}`, r])
        )

        // Update entity reference nodes in-place
        const updateBlocks = (blocks) => {
          for (const block of blocks) {
            if (Array.isArray(block.content)) {
              let needsUpdate = false
              const updatedContent = block.content.map((inline) => {
                if (inline.type !== 'entityReference') return inline
                const key = `${inline.props.entityType}:${inline.props.entityId}`
                const data = resolvedMap.get(key)
                if (!data) return inline
                needsUpdate = true
                return {
                  ...inline,
                  props: {
                    ...inline.props,
                    entityName: data.entityName || inline.props.entityName,
                    url: data.url || ''
                  }
                }
              })
              if (needsUpdate) {
                editor.updateBlock(block, { content: updatedContent })
              }
            }
            if (block.children) updateBlocks(block.children)
          }
        }

        updateBlocks(editor.document)
      } catch (error) {
        console.error('BlockEditor: Failed to resolve entity references:', error)
      }
    }

    // Small delay to ensure document is fully loaded (accounts for HTML parse path)
    const timer = setTimeout(resolveEntityReferences, 100)
    return () => clearTimeout(timer)
  }, [editor, referencesResolveUrl])

  return { getEntityReferenceItems }
}
