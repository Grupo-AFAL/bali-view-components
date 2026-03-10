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
import { createPortal } from 'react-dom'
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
  tableOfContentsContainerId,
  comments: commentsEnabled = false,
  commentsContainerId,
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

  // Parse content, detecting format:
  // - Array → BlockNote blocks (legacy/default)
  // - { type: "doc" } → ProseMirror JSON (preserves comment marks)
  const { parsedContent, pmContent } = useMemo(() => {
    if (!initialContent) return { parsedContent: undefined, pmContent: undefined }
    try {
      const parsed = typeof initialContent === 'string' ? JSON.parse(initialContent) : initialContent
      if (parsed && parsed.type === 'doc') {
        // ProseMirror JSON — will be loaded via setContent after editor init.
        // Delay content sync until setContent completes to prevent auto-save
        // from overwriting the document with empty content.
        ready.current = false
        return { parsedContent: undefined, pmContent: parsed }
      }
      return {
        parsedContent: Array.isArray(parsed) && parsed.length > 0 ? parsed : undefined,
        pmContent: undefined
      }
    } catch {
      return { parsedContent: undefined, pmContent: undefined }
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

  // Restore ProseMirror JSON content (preserves comment marks).
  // This handles content saved via _tiptapEditor.getJSON() when comments were active.
  // Strips marks not registered in the current editor schema to avoid tiptap errors
  // (e.g. "comment" marks when CommentsExtension is not loaded).
  const pmContentApplied = useRef(false)
  useEffect(() => {
    if (pmContent && editor && !pmContentApplied.current) {
      pmContentApplied.current = true
      const schema = editor._tiptapEditor.schema
      const strip = (node) => {
        if (!node) return node
        const result = { ...node }
        if (result.marks) {
          result.marks = result.marks.filter(m => schema.marks[m.type])
          if (result.marks.length === 0) delete result.marks
        }
        if (result.content) result.content = result.content.map(strip)
        return result
      }
      editor._tiptapEditor.commands.setContent(strip(pmContent))
      ready.current = true
    }
  }, [editor, pmContent])

  // Pre-populate the UserStore cache with all known users so that
  // resolved threads don't crash when BlockNote's Comments component
  // calls getUser() before async resolution completes.
  // We gate BlockNoteView's comments prop AND ThreadsSidebar on
  // commentsReady to ensure the cache is populated before any
  // resolved-thread UI mounts.
  const [commentsReady, setCommentsReady] = useState(!commentsEnabled)
  useEffect(() => {
    if (!editor || !commentsResult?.staticUserMap) return
    // editor.extensions is a Map<key, extension>, not an array
    if (editor.extensions) {
      for (const [, ext] of editor.extensions) {
        if (ext.userStore?.userCache) {
          for (const [id, user] of commentsResult.staticUserMap) {
            ext.userStore.userCache.set(id, user)
          }
          break
        }
      }
    }
    setCommentsReady(true)
  }, [editor, commentsResult])

  // Expose editor instance to the parent (Stimulus controller) for export functionality
  useEffect(() => {
    if (editor && onEditorReady) {
      onEditorReady(editor)
    }
  }, [editor, onEditorReady])

  // Prevent BlockNote's AI menu from jumping page scroll when the editor is already visible.
  // Two scroll sources cause this:
  //   1. xl-ai's openAIMenuAtBlock() calls Element.scrollIntoView({ block: "center" })
  //   2. ProseMirror transactions with .scrollIntoView() manipulate scrollTop directly
  // We suppress #1 via prototype override, and catch #2 by saving/restoring scroll position.
  useEffect(() => {
    if (!editor) return

    let savedScrollY = null
    let restoreId = null

    const scheduleRestore = () => {
      if (restoreId) cancelAnimationFrame(restoreId)
      restoreId = requestAnimationFrame(() => {
        restoreId = requestAnimationFrame(() => {
          if (savedScrollY !== null && window.scrollY !== savedScrollY) {
            window.scrollTo(0, savedScrollY)
          }
          savedScrollY = null
          restoreId = null
        })
      })
    }

    const original = Element.prototype.scrollIntoView
    Element.prototype.scrollIntoView = function (opts) {
      const editorEl = editor.domElement
      if (editorEl && editorEl.contains(this)) {
        const rect = this.getBoundingClientRect()
        if (rect.height > 0 && rect.top >= 0 && rect.bottom <= window.innerHeight) {
          // Element is visible — suppress and lock scroll position to catch
          // any ProseMirror transaction-level scrolling in the same frame
          if (savedScrollY === null) savedScrollY = window.scrollY
          scheduleRestore()
          return
        }
      }
      original.call(this, opts)
    }

    return () => {
      Element.prototype.scrollIntoView = original
      if (restoreId) cancelAnimationFrame(restoreId)
    }
  }, [editor])

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
  // BlockNote context. When commentsContainerId is provided, portal the
  // sidebar into an external container (e.g. DocumentEditor's side panel),
  // following the same pattern as the TOC portal.
  const commentsPortalContainer = commentsContainerId
    ? document.getElementById(commentsContainerId)
    : null

  const editorView = (
    <div className={commentsEnabled && !commentsPortalContainer ? 'bn-with-comments' : undefined}>
      <BlockNoteView
        editor={editor}
        editable={editable}
        theme={theme}
        onChange={handleChangeWithToc}
        slashMenu={false}
        formattingToolbar={needsCustomToolbar ? false : undefined}
        comments={commentsEnabled && commentsReady}
      >
        {editorChildren}
        {commentsEnabled && commentsReady && !commentsPortalContainer && <ThreadsSidebar filter='all' />}
        {commentsEnabled && commentsReady && commentsPortalContainer && createPortal(<ThreadsSidebar filter='all' />, commentsPortalContainer)}
      </BlockNoteView>
    </div>
  )

  // Portal mode: render TOC into an external DOM container (e.g. DocumentEditor's side panel)
  const tocPortalContainer = tableOfContentsContainerId
    ? document.getElementById(tableOfContentsContainerId)
    : null

  if (tableOfContents && tocPortalContainer) {
    return (
      <>
        {createPortal(<TableOfContents headings={tocHeadings} editorElement={editor?.domElement} />, tocPortalContainer)}
        {editorView}
      </>
    )
  }

  // Inline mode: render TOC alongside editor in flex layout
  if (tableOfContents) {
    return (
      <div className='bn-toc-layout'>
        <TableOfContents headings={tocHeadings} editorElement={editor?.domElement} />
        <div className='bn-toc-editor-wrapper'>{editorView}</div>
      </div>
    )
  }

  return editorView
}
