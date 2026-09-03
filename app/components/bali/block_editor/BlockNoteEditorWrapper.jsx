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
  BasicTextStyleButton,
  BlockTypeSelect,
  CreateLinkButton,
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
  markdownContent,
  editable = true,
  placeholder,
  format = 'json',
  preset = 'full',
  locale = 'en',
  syntaxHighlighting = true,
  uploadUrl,
  outputElement,
  // The `.block-editor-component` element this editor lives in. Upload errors are
  // rendered inside it, so two editors on one page never share a toast corner.
  containerElement,
  onEditorReady,
  onSyncReady,
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
  commentsSidebar = 'interactive',
  commentsUrl,
  commentsUser,
  commentsUsers,
  commentsUsersUrl,
  commentsPollInterval,
  commentsThreads,
  // Rails-supplied UI strings, keyed as in config/locales/bali_view.*.yml. The
  // hooks below used to hardcode them in English regardless of the app's locale.
  translations = {}
}) {
  const htmlParsed = useRef(false)
  // Deferred content (HTML/Markdown) is applied after mount; hold back the
  // content sync until then so autosave doesn't overwrite the document with
  // the empty initial state.
  const ready = useRef(!htmlContent && !markdownContent)
  const simple = preset === 'simple'
  const aiEnabled = !!(aiUrl && ai)
  const mentionsEnabled = !!(mentionsUrl || (staticMentions && staticMentions.length > 0))
  const referencesEnabled = !!referencesUrl

  const uploadFile = useFileUpload(uploadUrl, containerElement, translations)

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

  // "Plain Text" is the one entry of the language list that is a description
  // rather than a proper name, so it is the one that needs translating.
  const supportedLanguages = useMemo(() => ({
    ...SUPPORTED_LANGUAGES,
    text: { ...SUPPORTED_LANGUAGES.text, name: translations.plain_text ?? SUPPORTED_LANGUAGES.text.name }
  }), [translations.plain_text])

  // Build schema with optional syntax highlighting, multi-column, and mentions support.
  //
  // `shiki` is a heavyweight optional dependency (~9 MB unminified with every
  // grammar) and is NOT declared as a peer. Each import() is awaited on its own
  // line inside the try: esbuild only treats a dynamic import as optional when
  // it can attribute the failure to a surrounding try, which it cannot do for
  // imports nested in a Promise.all argument list. Written this way, an app that
  // never installs shiki still builds, and code blocks simply render unhighlighted.
  const schema = useMemo(() => {
    const codeBlock = syntaxHighlighting
      ? createCodeBlockSpec({
        supportedLanguages,
        defaultLanguage: 'text',
        createHighlighter: async () => {
          try {
            const { createHighlighter } = await import('shiki')
            const { createJavaScriptRegexEngine } = await import('shiki/engine/javascript')
            return createHighlighter({
              themes: ['github-light', 'github-dark'],
              langs: PRELOADED_LANGS,
              engine: createJavaScriptRegexEngine()
            })
          } catch (error) {
            console.error('BlockEditor: syntax highlighting is on but `shiki` could not be loaded. Install it, or pass syntax_highlighting: false.', error)
            throw error
          }
        }
      })
      : defaultBlockSpecs.codeBlock

    const base = BlockNoteSchema.create({
      blockSpecs: {
        ...defaultBlockSpecs,
        codeBlock
      },
      inlineContentSpecs: {
        ...defaultInlineContentSpecs,
        mention: Mention,
        entityReference: EntityReference
      }
    })
    return multiColumn ? multiColumn.withMultiColumn(base) : base
  }, [multiColumn, syntaxHighlighting, supportedLanguages])

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
    commentsUrl: commentsEnabled ? commentsUrl : undefined,
    commentsPollInterval: commentsEnabled ? commentsPollInterval : undefined,
    commentsThreads: commentsEnabled ? commentsThreads : undefined,
    translations
  })

  const extensions = useMemo(() => {
    const exts = []
    if (aiExtension) exts.push(aiExtension)
    if (commentsResult?.extension) exts.push(commentsResult.extension)
    return exts.length > 0 ? exts : undefined
  }, [aiExtension, commentsResult])

  // BlockNote ships ~23 locales; fall back to English for an unknown tag rather
  // than rendering an editor with no labels at all.
  const dictionary = useMemo(() => {
    const base = coreLocales[locale] ?? coreLocales.en
    return {
      ...base,
      ...(multiColumn ? { multi_column: (multiColumn.locales[locale] ?? multiColumn.locales.en) } : {}),
      ...(aiEnabled ? { ai: (ai.aiLocales[locale] ?? ai.aiLocales.en) } : {})
    }
  }, [locale, multiColumn, aiEnabled, ai])

  // The default placeholder advertises the "/" slash menu, which the simple
  // preset turns off. Promising a menu that never opens is worse than no hint.
  const placeholders = useMemo(() => {
    if (placeholder) return { default: placeholder }
    if (simple) return { default: '' }
    return undefined
  }, [placeholder, simple])

  const editor = useCreateBlockNote({
    schema,
    dropCursor: multiColumn?.multiColumnDropCursor,
    dictionary,
    initialContent: parsedContent,
    uploadFile: uploadUrl ? uploadFile : undefined,
    placeholders,
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
  const { handleChange, flush } = useContentSync(editor, outputElement, format, ready)

  // Hand the synchronous flush to the Stimulus controller so it can write the
  // pending content on form submit. Without it, submitting inside the debounce
  // window posts the previous content and the last edits are lost silently.
  useEffect(() => {
    if (onSyncReady) onSyncReady(flush)
  }, [onSyncReady, flush])

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

  // The user store is created by the comments extension, so it only exists once
  // the editor does. Hand it to useComments, which is what keeps every user id a
  // thread references answerable before BlockNote renders that thread -- read
  // the note there for why that has to happen, and why it cannot wait for the
  // async resolution. The comments UI stays gated on commentsReady so it never
  // mounts against a store nobody has seeded.
  const [commentsReady, setCommentsReady] = useState(!commentsEnabled)
  useEffect(() => {
    if (!editor || !commentsResult) return
    // editor.extensions is a Map<key, extension>, not an array
    for (const [, ext] of editor.extensions ?? []) {
      if (typeof ext.userStore?.getUser !== 'function') continue
      commentsResult.attachUserStore(ext.userStore)
      break
    }
    setCommentsReady(true)
  }, [editor, commentsResult])

  // Expose editor instance to the parent (Stimulus controller) for export functionality,
  // and give the ThreadStore a reference so it can remove marks on thread deletion.
  useEffect(() => {
    if (editor && onEditorReady) {
      onEditorReady(editor)
    }
    if (editor && commentsResult?.threadStore?.setEditor) {
      commentsResult.threadStore.setEditor(editor)
    }
  }, [editor, onEditorReady, commentsResult])

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

  // Load deferred HTML/Markdown content after mount if no JSON content was provided.
  //
  // BlockNote's parsers became synchronous in 0.51 (they returned promises
  // before), so the result is awaited rather than chained with .then() — calling
  // .then() on a plain array throws.
  useEffect(() => {
    const deferred = markdownContent
      ? { text: markdownContent, parse: () => editor.tryParseMarkdownToBlocks(markdownContent), label: 'Markdown' }
      : htmlContent
        ? { text: htmlContent, parse: () => editor.tryParseHTMLToBlocks(htmlContent), label: 'HTML' }
        : null

    if (parsedContent || !deferred || !editor || htmlParsed.current) return

    htmlParsed.current = true
    ;(async () => {
      try {
        const blocks = await deferred.parse()
        if (blocks && blocks.length > 0) {
          editor.replaceBlocks(editor.document, blocks)
        }
      } catch (error) {
        console.error(`BlockEditor: Failed to parse ${deferred.label} content:`, error)
      } finally {
        ready.current = true
      }
    })()
  }, [editor, htmlContent, markdownContent, parsedContent])

  // What the sidebar's mode hides is a look, so it is CSS — and CSS needs an
  // ancestor to hang the flag off. Rails puts it on the editor's root, which is an
  // ancestor of the inline sidebar and stops being one the moment
  // `comments_container_id:` portals the sidebar into a container of the host's.
  // Rails cannot put it there either: that container is the host's markup, and its
  // contents are React's. So the flag travels with the portal.
  //
  // Without this, `comments: { sidebar: :read_only }` plus `comments_container_id:`
  // rendered a fully interactive panel — no error, no warning, the opposite of what
  // the call site asked for (#1113). DocumentEditor was the only portaling caller
  // that worked, and only because it happens to render its own flagged panel
  // around the container.
  //
  // Both modes are written, not just `read-only`: the attribute is the documented
  // hook, and a host reading it should not have to tell "interactive" apart from
  // "this editor is too old to say".
  useEffect(() => {
    if (!commentsEnabled || !commentsContainerId) return

    const container = document.getElementById(commentsContainerId)
    if (!container) return

    const previous = container.getAttribute('data-comments-sidebar')
    container.setAttribute('data-comments-sidebar', commentsSidebar)

    return () => {
      if (previous === null) container.removeAttribute('data-comments-sidebar')
      else container.setAttribute('data-comments-sidebar', previous)
    }
  }, [commentsEnabled, commentsContainerId, commentsSidebar])

  // Custom toolbar when AI is enabled (to add the AI button) or in the simple
  // preset (to cut the toolbar down to inline formatting).
  // Otherwise the comments button is already included by getFormattingToolbarItems()
  // and BlockNoteView handles FloatingComposer/FloatingThread via comments prop.
  const needsCustomToolbar = aiEnabled || simple

  // The simple preset restricts the UI, never the schema: the editor must still
  // be able to represent every construct already present in stored content, or
  // opening and saving a record would destroy the parts it can't model.
  const simpleToolbar = (
    <FormattingToolbar>
      <BlockTypeSelect key='blockType' />
      <BasicTextStyleButton basicTextStyle='bold' key='bold' />
      <BasicTextStyleButton basicTextStyle='italic' key='italic' />
      <BasicTextStyleButton basicTextStyle='strike' key='strike' />
      <BasicTextStyleButton basicTextStyle='code' key='code' />
      <CreateLinkButton key='link' />
    </FormattingToolbar>
  )

  const editorChildren = (
    <>
      {!simple && (
        <SuggestionMenuController
          triggerCharacter='/'
          getItems={getSlashMenuItems}
        />
      )}
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
            simple
              ? simpleToolbar
              : (
                <FormattingToolbar>
                  {getFormattingToolbarItems()}
                  {aiEnabled && <ai.AIToolbarButton key='aiButton' />}
                </FormattingToolbar>
                )
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
        sideMenu={simple ? false : undefined}
        filePanel={simple ? false : undefined}
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
        {createPortal(<TableOfContents headings={tocHeadings} editorElement={editor?.domElement} label={translations.table_of_contents} />, tocPortalContainer)}
        {editorView}
      </>
    )
  }

  // Inline mode: render TOC alongside editor in flex layout
  if (tableOfContents) {
    return (
      <div className='bn-toc-layout'>
        <TableOfContents headings={tocHeadings} editorElement={editor?.domElement} label={translations.table_of_contents} />
        <div className='bn-toc-editor-wrapper'>{editorView}</div>
      </div>
    )
  }

  return editorView
}
