// The entry of `table` for the language `element` is in, read off its nearest `lang` as the
// browser does. Without one, or in a language with no entry, English.
export function inLanguageOf (element, table) {
  const lang = element.closest('[lang]')?.lang.toLowerCase().split(/[-_]/)[0]
  return table[lang] || table.en
}
