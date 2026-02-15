import '@blocknote/core/fonts/inter.css'
import '@blocknote/mantine/style.css'
// Our DaisyUI overrides - MUST load AFTER BlockNote CSS for correct cascade
import './index.css'

import {
  BlockNoteSchema,
  defaultBlockSpecs,
  defaultInlineContentSpecs,
  createCodeBlockSpec,
  combineByGroup
} from '@blocknote/core'
import * as coreLocales from '@blocknote/core/locales'
import { BlockNoteView } from '@blocknote/mantine'
import {
  useCreateBlockNote,
  createReactInlineContentSpec,
  SuggestionMenuController,
  getDefaultReactSlashMenuItems,
  FormattingToolbarController,
  FormattingToolbar,
  getFormattingToolbarItems
} from '@blocknote/react'
import { useEffect, useCallback, useRef, useMemo } from 'react'
import {
  withMultiColumn,
  multiColumnDropCursor,
  getMultiColumnSlashMenuItems,
  locales as multiColumnLocales
} from '@blocknote/xl-multi-column'

// Client-side max size check for UX only. The server endpoint MUST independently
// validate file type (via magic bytes), file size, and file extension.
const MAX_UPLOAD_SIZE = 10 * 1024 * 1024 // 10MB

// Languages supported in the code block language selector.
// This list also controls which languages shiki will highlight.
const SUPPORTED_LANGUAGES = {
  javascript: { name: 'JavaScript', aliases: ['js', 'jsx'] },
  typescript: { name: 'TypeScript', aliases: ['ts', 'tsx'] },
  python: { name: 'Python', aliases: ['py'] },
  ruby: { name: 'Ruby', aliases: ['rb'] },
  html: { name: 'HTML' },
  css: { name: 'CSS' },
  json: { name: 'JSON' },
  bash: { name: 'Bash', aliases: ['sh', 'shell', 'zsh'] },
  sql: { name: 'SQL' },
  yaml: { name: 'YAML', aliases: ['yml'] },
  markdown: { name: 'Markdown', aliases: ['md'] },
  xml: { name: 'XML' },
  java: { name: 'Java' },
  go: { name: 'Go', aliases: ['golang'] },
  rust: { name: 'Rust', aliases: ['rs'] },
  php: { name: 'PHP' },
  c: { name: 'C' },
  cpp: { name: 'C++', aliases: ['c++'] },
  csharp: { name: 'C#', aliases: ['cs', 'c#'] },
  swift: { name: 'Swift' },
  kotlin: { name: 'Kotlin', aliases: ['kt'] },
  text: { name: 'Plain Text', aliases: ['txt', 'plaintext', 'none'] }
}

// Languages to pre-load in the highlighter for instant highlighting.
// Other supported languages will be lazy-loaded on first use.
const PRELOADED_LANGS = [
  'javascript', 'typescript', 'python', 'ruby', 'html', 'css', 'json', 'bash', 'sql'
]

// Mention inline content - renders as a styled chip with @ prefix
const Mention = createReactInlineContentSpec(
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

// Default entity type display configuration.
// Host apps can override via the referencesConfig prop (from references_config: in Ruby).
// Colors use DaisyUI semantic names which are resolved to CSS vars at render time.
const DEFAULT_ENTITY_TYPE_CONFIG = {
  task: { icon: '\u2610', label: 'Task', color: 'info' },
  project: { icon: '\u25C8', label: 'Project', color: 'accent' },
  document: { icon: '\u25E7', label: 'Document', color: 'success' },
  default: { icon: '#', label: '', color: 'secondary' }
}

// Module-level config ref that the static render function can access.
// Updated by the component when referencesConfig prop is provided.
let activeEntityConfig = DEFAULT_ENTITY_TYPE_CONFIG

// Resolve a color name to a CSS variable reference.
// Accepts DaisyUI names ('info'), full var() refs, hex, or rgb values.
const resolveColor = (color) => {
  if (!color) return undefined
  if (color.startsWith('var(') || color.startsWith('#') || color.startsWith('rgb')) return color
  return `var(--color-${color})`
}

// Entity reference inline content - renders as a styled chip with type icon and label
const EntityReference = createReactInlineContentSpec(
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

export default function BlockNoteEditorWrapper ({
  initialContent,
  htmlContent,
  editable = true,
  placeholder,
  format = 'json',
  imagesUrl,
  outputElement,
  onEditorReady,
  theme = 'light',
  aiUrl,
  ai,
  mentionsUrl,
  mentions: staticMentions,
  referencesUrl,
  referencesResolveUrl,
  referencesConfig
}) {
  const htmlParsed = useRef(false)
  const ready = useRef(!htmlContent)
  const aiEnabled = !!(aiUrl && ai)
  const mentionsEnabled = !!(mentionsUrl || (staticMentions && staticMentions.length > 0))
  const referencesEnabled = !!referencesUrl

  // Merge host-provided entity type config with defaults
  useMemo(() => {
    if (!referencesConfig || Object.keys(referencesConfig).length === 0) {
      activeEntityConfig = DEFAULT_ENTITY_TYPE_CONFIG
      return
    }
    const merged = { ...DEFAULT_ENTITY_TYPE_CONFIG }
    for (const [type, overrides] of Object.entries(referencesConfig)) {
      merged[type] = { ...(DEFAULT_ENTITY_TYPE_CONFIG[type] || DEFAULT_ENTITY_TYPE_CONFIG.default), ...overrides }
    }
    activeEntityConfig = merged
  }, [referencesConfig])

  const uploadFile = useCallback(async (file) => {
    if (!imagesUrl) throw new Error('File uploads are not configured')

    if (file.size > MAX_UPLOAD_SIZE) {
      throw new Error('File size exceeds maximum of 10MB')
    }

    const formData = new FormData()
    formData.append('file', file)

    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    if (!csrfMeta) {
      throw new Error('CSRF token meta tag not found. Ensure csrf_meta_tags is in your layout.')
    }

    const response = await fetch(imagesUrl, {
      method: 'POST',
      body: formData,
      headers: { 'X-CSRF-Token': csrfMeta.content }
    })

    if (!response.ok) throw new Error('Upload failed')

    const data = await response.json()
    if (data.url && (data.url.startsWith('/') || /^https?:\/\//i.test(data.url))) {
      return data.url
    }
    throw new Error('Invalid URL returned from upload endpoint')
  }, [imagesUrl])

  const parsedContent = useMemo(() => {
    if (!initialContent) return undefined
    try {
      const parsed = typeof initialContent === 'string' ? JSON.parse(initialContent) : initialContent
      return Array.isArray(parsed) && parsed.length > 0 ? parsed : undefined
    } catch {
      return undefined
    }
  }, [initialContent])

  // Build schema with syntax highlighting, multi-column, and mentions support
  const schema = useMemo(() => withMultiColumn(BlockNoteSchema.create({
    blockSpecs: {
      ...defaultBlockSpecs,
      codeBlock: createCodeBlockSpec({
        supportedLanguages: SUPPORTED_LANGUAGES,
        defaultLanguage: 'text',
        createHighlighter: async () => {
          try {
            const [{ createHighlighter }, { createJavaScriptRegexEngine }] = await Promise.all([
              import('shiki'),
              import('shiki/engine/javascript')
            ])
            return createHighlighter({
              themes: ['github-light', 'github-dark'],
              langs: PRELOADED_LANGS,
              engine: createJavaScriptRegexEngine()
            })
          } catch (error) {
            console.error('BlockEditor: Failed to initialize syntax highlighter:', error)
            throw error
          }
        }
      })
    },
    inlineContentSpecs: {
      ...defaultInlineContentSpecs,
      mention: Mention,
      entityReference: EntityReference
    }
  })), [])

  const aiExtension = useMemo(() => {
    if (!aiEnabled) return null
    return ai.AIExtension({
      transport: new ai.DefaultChatTransport({ api: aiUrl })
    })
  }, [aiEnabled, aiUrl, ai])

  const editor = useCreateBlockNote({
    schema,
    dropCursor: multiColumnDropCursor,
    dictionary: {
      ...coreLocales.en,
      multi_column: multiColumnLocales.en,
      ...(aiEnabled ? { ai: ai.aiLocales.en } : {})
    },
    initialContent: parsedContent,
    uploadFile: imagesUrl ? uploadFile : undefined,
    placeholders: placeholder ? { default: placeholder } : undefined,
    extensions: aiExtension ? [aiExtension] : undefined
  })

  // Combine default + multi-column + AI slash menu items
  const getSlashMenuItems = useMemo(() => {
    return async (query) => {
      const groups = [
        getDefaultReactSlashMenuItems(editor),
        getMultiColumnSlashMenuItems(editor)
      ]
      if (aiEnabled) {
        groups.push(ai.getAISlashMenuItems(editor))
      }
      const items = combineByGroup(...groups)
      if (!query) return items
      const q = query.toLowerCase()
      return items.filter(item =>
        item.title.toLowerCase().includes(q) ||
        item.aliases?.some(a => a.toLowerCase().includes(q))
      )
    }
  }, [editor, aiEnabled, ai])

  // Fetch mention suggestions from server or filter static list
  const getMentionItems = useCallback(async (query) => {
    let users = []

    if (mentionsUrl) {
      try {
        const url = new URL(mentionsUrl, window.location.origin)
        if (query) url.searchParams.set('q', query)
        const response = await fetch(url, {
          headers: { Accept: 'application/json' }
        })
        if (response.ok) {
          users = await response.json()
        }
      } catch (error) {
        console.error('BlockEditor: Failed to fetch mentions:', error)
      }
    } else if (staticMentions) {
      users = staticMentions
    }

    const items = users.map((user) => {
      const name = typeof user === 'string' ? user : user.name
      const id = typeof user === 'string' ? user : (user.id || user.name)
      return {
        title: name,
        onItemClick: () => {
          editor.insertInlineContent([
            { type: 'mention', props: { user: name, id: String(id) } },
            ' '
          ])
        }
      }
    })

    if (!query) return items
    const q = query.toLowerCase()
    return items.filter(item => item.title.toLowerCase().includes(q))
  }, [editor, mentionsUrl, staticMentions])

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

      return refs.map((ref) => {
        const config = activeEntityConfig[ref.entityType] || activeEntityConfig.default
        return {
          title: ref.entityName,
          subtext: config.label,
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

  // Expose editor instance to the parent (Stimulus controller) for export functionality
  useEffect(() => {
    if (editor && onEditorReady) {
      onEditorReady(editor)
    }
  }, [editor, onEditorReady])

  // Load HTML content after mount if no JSON content was provided
  useEffect(() => {
    if (!parsedContent && htmlContent && editor && !htmlParsed.current) {
      htmlParsed.current = true
      editor.tryParseHTMLToBlocks(htmlContent).then((blocks) => {
        if (blocks && blocks.length > 0) {
          editor.replaceBlocks(editor.document, blocks)
        }
      }).catch((error) => {
        console.error('BlockEditor: Failed to parse HTML content:', error)
      }).finally(() => {
        ready.current = true
      })
    }
  }, [editor, htmlContent, parsedContent])

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
                for (const inline of cell) {
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

  // Sync content to hidden input on changes (debounced)
  const pendingUpdate = useRef(null)
  const handleChange = useCallback(() => {
    if (!outputElement || !editor || !ready.current) return

    if (pendingUpdate.current) clearTimeout(pendingUpdate.current)

    pendingUpdate.current = setTimeout(async () => {
      try {
        if (format === 'html') {
          const html = await editor.blocksToHTMLLossy(editor.document)
          outputElement.value = html
        } else {
          outputElement.value = JSON.stringify(editor.document)
        }
      } catch (error) {
        console.error('BlockEditor: Failed to serialize content:', error)
      }
    }, 300)
  }, [editor, outputElement, format])

  return (
    <BlockNoteView
      editor={editor}
      editable={editable}
      theme={theme}
      onChange={handleChange}
      slashMenu={false}
      formattingToolbar={aiEnabled ? false : undefined}
    >
      <SuggestionMenuController
        triggerCharacter='/'
        getItems={getSlashMenuItems}
      />
      {mentionsEnabled && (
        <SuggestionMenuController
          triggerCharacter='@'
          getItems={getMentionItems}
        />
      )}
      {referencesEnabled && (
        <SuggestionMenuController
          triggerCharacter='#'
          getItems={getEntityReferenceItems}
        />
      )}
      {aiEnabled && (
        <FormattingToolbarController
          formattingToolbar={() => (
            <FormattingToolbar>
              {getFormattingToolbarItems()}
              <ai.AIToolbarButton key='aiButton' />
            </FormattingToolbar>
          )}
        />
      )}
      {aiEnabled && <ai.AIMenuController />}
    </BlockNoteView>
  )
}
