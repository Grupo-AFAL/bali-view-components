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

// What the PDF and Word exporters colour text and highlights with: BlockNote's own light palette
// (COLORS_DEFAULT) with the four text colours index.css darkens for the light themes. The
// exporters paint on white paper, where BlockNote's yellow measured 2.11:1. index.css declares
// the same four: change one, change the other.
export const EXPORT_COLORS = {
  gray: { text: '#767572', background: '#ebeced' },
  brown: { text: '#64473a', background: '#e9e5e3' },
  red: { text: '#d93638', background: '#fbe4e4' },
  orange: { text: '#ba5700', background: '#f6e9d9' },
  yellow: { text: '#9d6b00', background: '#fbf3db' },
  green: { text: '#4d6461', background: '#ddedea' },
  blue: { text: '#0b6e99', background: '#ddebf1' },
  purple: { text: '#6940a5', background: '#eae4f2' },
  pink: { text: '#ad1a72', background: '#f4dfeb' }
}
