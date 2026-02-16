// Client-side max size check for UX only. The server endpoint MUST independently
// validate file type (via magic bytes), file size, and file extension.
export const MAX_UPLOAD_SIZE = 50 * 1024 * 1024 // 50MB

// Languages supported in the code block language selector.
// This list also controls which languages shiki will highlight.
export const SUPPORTED_LANGUAGES = {
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
export const PRELOADED_LANGS = [
  'javascript', 'typescript', 'python', 'ruby', 'html', 'css', 'json', 'bash', 'sql'
]
