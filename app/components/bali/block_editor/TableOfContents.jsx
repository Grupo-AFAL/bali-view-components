import { useCallback } from 'react'

export default function TableOfContents ({ headings, editorElement }) {
  const scrollToBlock = useCallback((id) => {
    // Scope query to the editor container to avoid matching elements in other
    // block editors on the same page (e.g., document show page with overlays)
    const root = editorElement || document
    const el = root.querySelector(`[data-id="${CSS.escape(id)}"]`)
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }, [editorElement])

  if (headings.length === 0) return null

  return (
    <nav className='bn-toc' aria-label='Table of contents'>
      <ul className='bn-toc-list'>
        {headings.map((heading) => (
          <li key={heading.id} className={`bn-toc-item bn-toc-level-${heading.level}`}>
            <button
              type='button'
              className='bn-toc-link'
              onClick={() => scrollToBlock(heading.id)}
              title={heading.text}
            >
              {heading.text}
            </button>
          </li>
        ))}
      </ul>
    </nav>
  )
}
