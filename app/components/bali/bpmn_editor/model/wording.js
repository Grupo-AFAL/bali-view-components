// How a name is worded, for the wording rules (rules.js). Every word list is
// an i18n entry (pipe-separated, i18n.js), so the checks follow the language
// of the UI and a host can rewrite any list through `i18n:`.
//
// Names and lists are compared without accents, case or punctuation:
// a word written with or without its accents is the same word.

export const plain = (text) => String(text || '')
  .normalize('NFD').replace(/[̀-ͯ]/g, '')
  .toLowerCase()
  .replace(/[¿?¡!.;:()"'«»“”]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim()

// Words, with a comma kept as its own token (several actions in one name).
export const tokens = (text) => plain(String(text || '').replace(/,/g, ' , ')).split(' ').filter(Boolean)
export const wordsOf = (text) => tokens(text).filter((w) => w !== ',')

// A list entry is one word or a phrase; the name starts with it.
export const startsWith = (text, phrases) => {
  const name = wordsOf(text).join(' ')
  return phrases.some((p) => name === p || name.startsWith(`${p} `))
}
export const contains = (text, phrases) => {
  const name = ` ${wordsOf(text).join(' ')} `
  return phrases.some((p) => name.includes(` ${p} `))
}

// `lists`: { verbs, endings, exceptions } — the action verbs, the infinitive
// endings (Spanish -ar/-er/-ir; empty in English, where only the verb list
// counts) and the words that end like an infinitive but are not («lugar»).
export function isInfinitive (word, lists) {
  const w = plain(word)
  if (!w) return false
  if (lists.verbs.includes(w)) return true
  if (lists.exceptions.includes(w)) return false
  return lists.endings.some((e) => w.length > e.length + 2 && w.endsWith(e))
}

export const isNominal = (word, endings) => {
  const w = plain(word)
  return endings.some((e) => w.length > e.length + 2 && w.endsWith(e))
}

// Verbs at the start of the name or right after a comma or a conjunction:
// "Review, authorize and record" has three; "Calculate the amount to pay" one.
export function actionsIn (text, lists, conjunctions) {
  const list = tokens(text)
  let count = 0
  list.forEach((word, i) => {
    const after = i === 0 || list[i - 1] === ',' || conjunctions.includes(list[i - 1])
    if (after && word !== ',' && isInfinitive(word, lists)) count++
  })
  return count
}

// Two lane names that read as the same participant: the same words, one of
// them abbreviated («Gte.» for «Gerente»), or a typo apart.
export function sameParticipant (a, b) {
  const x = wordsOf(a)
  const y = wordsOf(b)
  if (!x.length || !y.length) return false
  if (x.join(' ') === y.join(' ')) return true
  if (x.length === y.length && x.every((w, i) => w === y[i] || abbreviates(w, y[i]) || abbreviates(y[i], w))) return true
  const joined = [x.join(' '), y.join(' ')]
  return Math.min(joined[0].length, joined[1].length) >= 6 && distance(joined[0], joined[1]) <= 1
}

// «gte» abbreviates «gerente»: same first letter, its letters in order.
function abbreviates (short, long) {
  if (short.length >= long.length || short[0] !== long[0]) return false
  let j = 0
  for (const ch of long) if (ch === short[j]) j++
  return j === short.length
}

function distance (a, b) {
  const row = Array.from({ length: b.length + 1 }, (_, i) => i)
  for (let i = 1; i <= a.length; i++) {
    let previous = row[0]
    row[0] = i
    for (let j = 1; j <= b.length; j++) {
      const current = row[j]
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, previous + (a[i - 1] === b[j - 1] ? 0 : 1))
      previous = current
    }
  }
  return row[b.length]
}
