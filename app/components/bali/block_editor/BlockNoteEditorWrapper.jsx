import '@blocknote/core/fonts/inter.css'
import '@blocknote/mantine/style.css'
// Our DaisyUI overrides - MUST load AFTER BlockNote CSS for correct cascade
import './index.css'

import { BlockNoteSchema, defaultBlockSpecs, createCodeBlockSpec } from '@blocknote/core'
import { BlockNoteView } from '@blocknote/mantine'
import { useCreateBlockNote } from '@blocknote/react'
import { useEffect, useCallback, useRef, useMemo } from 'react'

// Client-side validation for UX only. The server endpoint MUST independently
// validate file type (via magic bytes), file size, and file extension.
const ALLOWED_UPLOAD_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
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

export default function BlockNoteEditorWrapper ({
  initialContent,
  htmlContent,
  editable = true,
  placeholder,
  format = 'json',
  imagesUrl,
  outputElement,
  theme = 'light'
}) {
  const htmlParsed = useRef(false)
  const ready = useRef(!htmlContent)

  const uploadFile = useCallback(async (file) => {
    if (!imagesUrl) throw new Error('Image uploads are not configured')

    if (!ALLOWED_UPLOAD_TYPES.includes(file.type)) {
      throw new Error('This file type is not supported. Accepted formats: JPEG, PNG, GIF, WebP.')
    }
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
    if (data.url && /^https?:\/\//i.test(data.url)) {
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

  // Build schema with syntax highlighting support (shiki is optional - degrades gracefully)
  const schema = useMemo(() => BlockNoteSchema.create({
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
    }
  }), [])

  const editor = useCreateBlockNote({
    schema,
    initialContent: parsedContent,
    uploadFile: imagesUrl ? uploadFile : undefined,
    placeholders: placeholder ? { default: placeholder } : undefined
  })

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
    />
  )
}
