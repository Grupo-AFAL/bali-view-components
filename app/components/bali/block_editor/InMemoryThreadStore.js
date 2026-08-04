import { ThreadStore, DefaultThreadStoreAuth } from '@blocknote/core/comments'

// Seeded threads arrive as JSON, where a timestamp is a string. BlockNote reads
// `createdAt`/`updatedAt` as Date objects and calls Date methods on them, so a string
// left as-is throws while rendering the thread — inside React's render, which takes the
// whole editor down rather than just the sidebar. Missing dates get "now", which is the
// only defensible guess and keeps a hand-written seed from having to carry them.
function toDate (value) {
  const date = value instanceof Date ? value : new Date(value)
  return Number.isNaN(date.getTime()) ? new Date() : date
}

function normalizeSeed (threads) {
  if (!Array.isArray(threads)) return []

  return threads.filter(thread => thread?.id).map(thread => ({
    type: 'thread',
    resolved: false,
    metadata: {},
    ...thread,
    id: String(thread.id),
    createdAt: toDate(thread.createdAt),
    updatedAt: toDate(thread.updatedAt ?? thread.createdAt),
    comments: (thread.comments ?? []).map(comment => ({
      type: 'comment',
      reactions: [],
      metadata: {},
      ...comment,
      id: String(comment.id),
      userId: String(comment.userId),
      createdAt: toDate(comment.createdAt),
      updatedAt: toDate(comment.updatedAt ?? comment.createdAt)
    }))
  }))
}

/**
 * In-memory ThreadStore implementation for BlockNote comments.
 *
 * Stores comment threads in a JavaScript Map for the duration of the editor
 * session. Threads are NOT persisted — they exist only while the page is open.
 *
 * Use this for previews, demos, or single-user note-taking where comments
 * don't need to survive page reloads. For persistent comments, host apps
 * should implement their own ThreadStore backed by a REST API.
 *
 * `seedThreads` gives the store a starting set. It is what lets a demo open with
 * threads already in the sidebar: the comments sidebar reads its threads from the
 * STORE, not from the document, so a seeded thread shows without the text carrying
 * a `comment` mark. That distinction is not a shortcut — BlockNote's comment mark
 * declares `blocknoteIgnore`, so it is deliberately absent from the block JSON and
 * cannot be expressed in `initial_content` at all. Seeded threads are therefore
 * anchorless: they list and read, and clicking one highlights nothing.
 */
export class InMemoryThreadStore extends ThreadStore {
  constructor (userId, role = 'editor', seedThreads = []) {
    super(new DefaultThreadStoreAuth(userId, role))
    this._userId = userId
    this._threads = new Map()
    this._subscribers = new Set()

    for (const thread of normalizeSeed(seedThreads)) {
      this._threads.set(thread.id, thread)
    }
  }

  _generateId () {
    return crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`
  }

  _notify () {
    const snapshot = new Map(this._threads)
    this._subscribers.forEach(cb => cb(snapshot))
  }

  _now () {
    return new Date()
  }

  async createThread ({ initialComment, metadata }) {
    const threadId = this._generateId()
    const commentId = this._generateId()
    const now = this._now()

    const comment = {
      type: 'comment',
      id: commentId,
      userId: this._userId,
      createdAt: now,
      updatedAt: now,
      body: initialComment.body,
      reactions: [],
      metadata: initialComment.metadata ?? {}
    }

    const thread = {
      type: 'thread',
      id: threadId,
      createdAt: now,
      updatedAt: now,
      comments: [comment],
      resolved: false,
      metadata: metadata ?? {}
    }

    this._threads.set(threadId, thread)
    this._notify()
    return thread
  }

  async addComment ({ comment: commentData, threadId }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    const now = this._now()
    const comment = {
      type: 'comment',
      id: this._generateId(),
      userId: this._userId,
      createdAt: now,
      updatedAt: now,
      body: commentData.body,
      reactions: [],
      metadata: commentData.metadata ?? {}
    }

    thread.comments.push(comment)
    thread.updatedAt = now
    this._notify()
    return comment
  }

  async updateComment ({ comment: commentData, threadId, commentId }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    const comment = thread.comments.find(c => c.id === commentId)
    if (!comment) throw new Error(`Comment ${commentId} not found`)

    comment.body = commentData.body
    comment.updatedAt = this._now()
    if (commentData.metadata !== undefined) {
      comment.metadata = commentData.metadata
    }
    thread.updatedAt = comment.updatedAt
    this._notify()
  }

  async deleteComment ({ threadId, commentId }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    const idx = thread.comments.findIndex(c => c.id === commentId)
    if (idx === -1) throw new Error(`Comment ${commentId} not found`)

    // Soft-delete: set deletedAt and remove body
    const comment = thread.comments[idx]
    comment.deletedAt = this._now()
    comment.body = undefined
    thread.updatedAt = comment.deletedAt
    this._notify()
  }

  async deleteThread ({ threadId }) {
    const thread = this._threads.get(threadId)
    if (!thread) return

    thread.deletedAt = this._now()
    this._threads.delete(threadId)
    this._notify()
  }

  async resolveThread ({ threadId }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    thread.resolved = true
    thread.resolvedBy = this._userId
    thread.resolvedUpdatedAt = this._now()
    thread.updatedAt = thread.resolvedUpdatedAt
    this._notify()
  }

  async unresolveThread ({ threadId }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    thread.resolved = false
    thread.resolvedBy = undefined
    thread.resolvedUpdatedAt = this._now()
    thread.updatedAt = thread.resolvedUpdatedAt
    this._notify()
  }

  async addReaction ({ threadId, commentId, emoji }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    const comment = thread.comments.find(c => c.id === commentId)
    if (!comment) throw new Error(`Comment ${commentId} not found`)

    const existing = comment.reactions.find(r => r.emoji === emoji)
    if (existing) {
      if (!existing.userIds.includes(this._userId)) {
        existing.userIds.push(this._userId)
      }
    } else {
      comment.reactions.push({
        emoji,
        createdAt: this._now(),
        userIds: [this._userId]
      })
    }
    thread.updatedAt = this._now()
    this._notify()
  }

  async deleteReaction ({ threadId, commentId, emoji }) {
    const thread = this._threads.get(threadId)
    if (!thread) throw new Error(`Thread ${threadId} not found`)

    const comment = thread.comments.find(c => c.id === commentId)
    if (!comment) throw new Error(`Comment ${commentId} not found`)

    const existing = comment.reactions.find(r => r.emoji === emoji)
    if (existing) {
      existing.userIds = existing.userIds.filter(id => id !== this._userId)
      if (existing.userIds.length === 0) {
        comment.reactions = comment.reactions.filter(r => r.emoji !== emoji)
      }
    }
    thread.updatedAt = this._now()
    this._notify()
  }

  getThread (threadId) {
    return this._threads.get(threadId)
  }

  getThreads () {
    return new Map(this._threads)
  }

  subscribe (cb) {
    this._subscribers.add(cb)
    return () => this._subscribers.delete(cb)
  }
}
