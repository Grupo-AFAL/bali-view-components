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
  SuggestionMenuController,
  getDefaultReactSlashMenuItems,
  FormattingToolbarController,
  FormattingToolbar,
  getFormattingToolbarItems
} from '@blocknote/react'
import { useEffect, useRef, useMemo } from 'react'

import { SUPPORTED_LANGUAGES, PRELOADED_LANGS } from './constants'
import { Mention, EntityReference } from './inlineContent'
import { useFileUpload } from './useFileUpload'
import { useContentSync } from './useContentSync'
import { useMentions } from './useMentions'
import { useEntityReferences } from './useEntityReferences'

export default function BlockNoteEditorWrapper ({
  initialContent,
  htmlContent,
  editable = true,
  placeholder,
  format = 'json',
  uploadUrl,
  outputElement,
  onEditorReady,
  theme = 'light',
  aiUrl,
  ai,
  multiColumn,
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

  const uploadFile = useFileUpload(uploadUrl)

  const parsedContent = useMemo(() => {
    if (!initialContent) return undefined
    try {
      const parsed = typeof initialContent === 'string' ? JSON.parse(initialContent) : initialContent
      return Array.isArray(parsed) && parsed.length > 0 ? parsed : undefined
    } catch {
      return undefined
    }
  }, [initialContent])

  // Build schema with syntax highlighting, optional multi-column, and mentions support
  const schema = useMemo(() => {
    const base = BlockNoteSchema.create({
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
    })
    return multiColumn ? multiColumn.withMultiColumn(base) : base
  }, [multiColumn])

  const aiExtension = useMemo(() => {
    if (!aiEnabled) return null
    return ai.AIExtension({
      transport: new ai.DefaultChatTransport({ api: aiUrl })
    })
  }, [aiEnabled, aiUrl, ai])

  const editor = useCreateBlockNote({
    schema,
    dropCursor: multiColumn?.multiColumnDropCursor,
    dictionary: {
      ...coreLocales.en,
      ...(multiColumn ? { multi_column: multiColumn.locales.en } : {}),
      ...(aiEnabled ? { ai: ai.aiLocales.en } : {})
    },
    initialContent: parsedContent,
    uploadFile: uploadUrl ? uploadFile : undefined,
    placeholders: placeholder ? { default: placeholder } : undefined,
    extensions: aiExtension ? [aiExtension] : undefined
  })

  // Combine default + optional multi-column + AI slash menu items
  const getSlashMenuItems = useMemo(() => {
    return async (query) => {
      const groups = [
        getDefaultReactSlashMenuItems(editor),
        ...(multiColumn ? [multiColumn.getMultiColumnSlashMenuItems(editor)] : [])
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
  }, [editor, multiColumn, aiEnabled, ai])

  const getMentionItems = useMentions(editor, mentionsUrl, staticMentions)
  const { getEntityReferenceItems } = useEntityReferences(editor, {
    referencesUrl,
    referencesResolveUrl,
    referencesConfig
  })
  const handleChange = useContentSync(editor, outputElement, format, ready)

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
