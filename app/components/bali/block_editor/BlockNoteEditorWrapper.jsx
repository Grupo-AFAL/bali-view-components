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
  getFormattingToolbarItems,
  ThreadsSidebar
} from '@blocknote/react'
import { useEffect, useRef, useMemo, useState, useCallback } from 'react'

import { SUPPORTED_LANGUAGES, PRELOADED_LANGS } from './constants'
import { Mention, EntityReference } from './inlineContent'
import { useFileUpload } from './useFileUpload'
import { useContentSync } from './useContentSync'
import { useMentions } from './useMentions'
import { useEntityReferences } from './useEntityReferences'
import { useComments } from './useComments'
import TableOfContents from './TableOfContents'

function extractTextFromContent (content) {
  if (!Array.isArray(content)) return ''
  return content.filter(item => item.type === 'text').map(item => item.text ?? '').join('')
}

function collectHeadings (blocks, result = []) {
  if (!Array.isArray(blocks)) return result
  for (const block of blocks) {
    if (block.type === 'heading') {
      const text = extractTextFromContent(block.content)
      if (text.trim()) result.push({ id: block.id, level: block.props?.level ?? 1, text })
    }
    if (Array.isArray(block.children) && block.children.length > 0) {
      collectHeadings(block.children, result)
    }
  }
  return result
}

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
  referencesConfig,
  tableOfContents = false,
  comments: commentsEnabled = false,
  commentsUrl,
  commentsUser,
  commentsUsers,
  commentsUsersUrl
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

  const commentsResult = useComments({
    commentsUser: commentsEnabled ? commentsUser : undefined,
    commentsUsers: commentsEnabled ? commentsUsers : undefined,
    commentsUsersUrl: commentsEnabled ? commentsUsersUrl : undefined,
    commentsUrl: commentsEnabled ? commentsUrl : undefined
  })

  const extensions = useMemo(() => {
    const exts = []
    if (aiExtension) exts.push(aiExtension)
    if (commentsResult?.extension) exts.push(commentsResult.extension)
    return exts.length > 0 ? exts : undefined
  }, [aiExtension, commentsResult])

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
    extensions
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

  const [tocHeadings, setTocHeadings] = useState(() =>
    tableOfContents ? collectHeadings(editor.document) : []
  )
  const tocTimeout = useRef(null)

  const handleChangeWithToc = useCallback(() => {
    handleChange()
    if (tableOfContents) {
      if (tocTimeout.current) clearTimeout(tocTimeout.current)
      tocTimeout.current = setTimeout(() => {
        setTocHeadings(collectHeadings(editor.document))
      }, 300)
    }
  }, [handleChange, tableOfContents, editor])

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

  // Only need a custom toolbar when AI is enabled (to add AI button).
  // Comments button is already included by getFormattingToolbarItems()
  // and BlockNoteView handles FloatingComposer/FloatingThread via comments prop.
  const needsCustomToolbar = aiEnabled

  const editorChildren = (
    <>
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
      {needsCustomToolbar && (
        <FormattingToolbarController
          formattingToolbar={() => (
            <FormattingToolbar>
              {getFormattingToolbarItems()}
              {aiEnabled && <ai.AIToolbarButton key='aiButton' />}
            </FormattingToolbar>
          )}
        />
      )}
      {aiEnabled && <ai.AIMenuController />}
    </>
  )

  // ThreadsSidebar must be a child of BlockNoteView for access to the
  // BlockNote context. We wrap the view in a CSS class so that
  // .bn-container gains flex layout to place the sidebar beside the editor.
  const editorView = (
    <div className={commentsEnabled ? 'bn-with-comments' : undefined}>
      <BlockNoteView
        editor={editor}
        editable={editable}
        theme={theme}
        onChange={handleChangeWithToc}
        slashMenu={false}
        formattingToolbar={needsCustomToolbar ? false : undefined}
        comments={commentsEnabled}
      >
        {editorChildren}
        {commentsEnabled && <ThreadsSidebar />}
      </BlockNoteView>
    </div>
  )

  if (tableOfContents) {
    return (
      <div className='bn-toc-layout'>
        <TableOfContents headings={tocHeadings} />
        <div className='bn-toc-editor-wrapper'>{editorView}</div>
      </div>
    )
  }

  return editorView
}
