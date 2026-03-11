import { ThreadStore, DefaultThreadStoreAuth } from '@blocknote/core/comments'

/**
 * REST-based ThreadStore for BlockNote comments.
 *
 * Persists comment threads via a REST API. The host app provides a base URL
 * and implements the endpoints. Threads are loaded on init and polled for
 * updates at a configurable interval.
 *
 * API Contract (all relative to `baseUrl`):
 *
 *   GET    /                          → list threads (with nested comments)
 *   POST   /                          → create thread
 *   DELETE /:threadId                 → delete thread
 *   PATCH  /:threadId                 → update thread (resolve/unresolve)
 *   POST   /:threadId/comments        → add comment
 *   PATCH  /:threadId/comments/:id    → update comment
 *   DELETE /:threadId/comments/:id    → delete comment
 *   POST   /:threadId/comments/:id/reactions    → add reaction
 *   DELETE /:threadId/comments/:id/reactions     → delete reaction (emoji in body)
 */
export class RESTThreadStore extends ThreadStore {
  constructor (userId, baseUrl, { role = 'editor', pollInterval = 5000 } = {}) {
    super(new DefaultThreadStoreAuth(userId, role))
    this._userId = userId
    // Parse the base URL to correctly handle query parameters in sub-requests
    this._parsedBaseUrl = new URL(baseUrl, window.location.origin)
    this._threads = new Map()
    this._subscribers = new Set()
    this._pollInterval = pollInterval
    this._pollTimer = null
    this._loading = false

    // Initial load + start polling
    this._loadThreads().then(() => this._startPolling())
  }

  // --- ThreadStore abstract methods ---

  async createThread ({ initialComment, metadata }) {
    const data = await this._post('', {
      initial_comment: {
        body: initialComment.body,
        metadata: initialComment.metadata
      },
      metadata
    })

    const thread = this._normalizeThread(data)
    this._threads.set(thread.id, thread)
    this._notify()
    return thread
  }

  async addComment ({ comment: commentData, threadId }) {
    const data = await this._post(`/${threadId}/comments`, {
      body: commentData.body,
      metadata: commentData.metadata
    })

    const comment = this._normalizeComment(data)
    const thread = this._threads.get(threadId)
    if (thread) {
      thread.comments.push(comment)
      thread.updatedAt = new Date()
      this._notify()
    }
    return comment
  }

  async updateComment ({ comment: commentData, threadId, commentId }) {
    await this._patch(`/${threadId}/comments/${commentId}`, {
      body: commentData.body,
      metadata: commentData.metadata
    })

    const thread = this._threads.get(threadId)
    if (thread) {
      const comment = thread.comments.find(c => c.id === commentId)
      if (comment) {
        comment.body = commentData.body
        comment.updatedAt = new Date()
        if (commentData.metadata !== undefined) {
          comment.metadata = commentData.metadata
        }
      }
      thread.updatedAt = new Date()
      this._notify()
    }
  }

  async deleteComment ({ threadId, commentId }) {
    await this._delete(`/${threadId}/comments/${commentId}`)

    const thread = this._threads.get(threadId)
    if (thread) {
      const comment = thread.comments.find(c => c.id === commentId)
      if (comment) {
        comment.deletedAt = new Date()
        comment.body = undefined
      }
      thread.updatedAt = new Date()
      this._notify()
    }
  }

  async deleteThread ({ threadId }) {
    await this._delete(`/${threadId}`)

    this._threads.delete(threadId)
    this._removeMarks(threadId)
    this._notify()
  }

  /**
   * Set a reference to the BlockNote editor so we can manipulate marks.
   * Called from BlockNoteEditorWrapper after the editor is created.
   */
  setEditor (editor) {
    this._editor = editor
  }

  async resolveThread ({ threadId }) {
    await this._patch(`/${threadId}`, { resolved: true })

    const thread = this._threads.get(threadId)
    if (thread) {
      thread.resolved = true
      thread.resolvedBy = this._userId
      thread.resolvedUpdatedAt = new Date()
      thread.updatedAt = new Date()
      this._notify()
    }
  }

  async unresolveThread ({ threadId }) {
    await this._patch(`/${threadId}`, { resolved: false })

    const thread = this._threads.get(threadId)
    if (thread) {
      thread.resolved = false
      thread.resolvedBy = undefined
      thread.resolvedUpdatedAt = new Date()
      thread.updatedAt = new Date()
      this._notify()
    }
  }

  async addReaction ({ threadId, commentId, emoji }) {
    await this._post(`/${threadId}/comments/${commentId}/reactions`, { emoji })

    const thread = this._threads.get(threadId)
    if (thread) {
      const comment = thread.comments.find(c => c.id === commentId)
      if (comment) {
        const existing = comment.reactions.find(r => r.emoji === emoji)
        if (existing) {
          if (!existing.userIds.includes(this._userId)) {
            existing.userIds.push(this._userId)
          }
        } else {
          comment.reactions.push({ emoji, createdAt: new Date(), userIds: [this._userId] })
        }
      }
      thread.updatedAt = new Date()
      this._notify()
    }
  }

  async deleteReaction ({ threadId, commentId, emoji }) {
    await this._deleteWithBody(`/${threadId}/comments/${commentId}/reactions`, { emoji })

    const thread = this._threads.get(threadId)
    if (thread) {
      const comment = thread.comments.find(c => c.id === commentId)
      if (comment) {
        const existing = comment.reactions.find(r => r.emoji === emoji)
        if (existing) {
          existing.userIds = existing.userIds.filter(id => id !== this._userId)
          if (existing.userIds.length === 0) {
            comment.reactions = comment.reactions.filter(r => r.emoji !== emoji)
          }
        }
      }
      thread.updatedAt = new Date()
      this._notify()
    }
  }

  getThread (threadId) {
    return this._threads.get(threadId)
  }

  getThreads () {
    return new Map(this._threads)
  }

  subscribe (cb) {
    this._subscribers.add(cb)
    return () => {
      this._subscribers.delete(cb)
      // Stop polling when no more subscribers
      if (this._subscribers.size === 0) {
        this._stopPolling()
      }
    }
  }

  // --- Public utilities ---

  destroy () {
    this._stopPolling()
    this._subscribers.clear()
  }

  // --- Private helpers ---

  _notify () {
    const snapshot = new Map(this._threads)
    this._subscribers.forEach(cb => cb(snapshot))
  }

  _startPolling () {
    if (this._pollInterval <= 0) return
    this._pollTimer = setInterval(() => this._loadThreads(), this._pollInterval)
  }

  _stopPolling () {
    if (this._pollTimer) {
      clearInterval(this._pollTimer)
      this._pollTimer = null
    }
  }

  async _loadThreads () {
    if (this._loading) return
    this._loading = true

    try {
      const data = await this._get('')
      if (!Array.isArray(data)) return

      const newThreads = new Map()
      for (const raw of data) {
        const thread = this._normalizeThread(raw)
        newThreads.set(thread.id, thread)
      }
      this._threads = newThreads
      this._notify()
    } catch (error) {
      console.error('BlockEditor: Failed to load comment threads:', error)
    } finally {
      this._loading = false
    }
  }

  _normalizeThread (raw) {
    return {
      type: 'thread',
      id: String(raw.id),
      createdAt: new Date(raw.created_at || raw.createdAt),
      updatedAt: new Date(raw.updated_at || raw.updatedAt),
      comments: (raw.comments || []).map(c => this._normalizeComment(c)),
      resolved: !!raw.resolved,
      resolvedBy: raw.resolved_by || raw.resolvedBy || undefined,
      resolvedUpdatedAt: raw.resolved_updated_at ? new Date(raw.resolved_updated_at) : undefined,
      metadata: raw.metadata || {},
      deletedAt: raw.deleted_at ? new Date(raw.deleted_at) : undefined
    }
  }

  _normalizeComment (raw) {
    const base = {
      type: 'comment',
      id: String(raw.id),
      userId: String(raw.user_id || raw.userId),
      createdAt: new Date(raw.created_at || raw.createdAt),
      updatedAt: new Date(raw.updated_at || raw.updatedAt),
      reactions: (raw.reactions || []).map(r => ({
        emoji: r.emoji,
        createdAt: new Date(r.created_at || r.createdAt),
        userIds: (r.user_ids || r.userIds || []).map(String)
      })),
      metadata: raw.metadata || {}
    }

    if (raw.deleted_at || raw.deletedAt) {
      base.deletedAt = new Date(raw.deleted_at || raw.deletedAt)
      base.body = undefined
    } else {
      base.body = this._normalizeCommentBody(raw.body)
    }

    return base
  }

  _normalizeCommentBody (body) {
    // BlockNote expects comment body as an array of blocks.
    // Handle string bodies by wrapping them in a paragraph block.
    if (typeof body === 'string') {
      return [{
        type: 'paragraph',
        content: [{ type: 'text', text: body, styles: {} }],
        children: []
      }]
    }
    return body
  }

  _buildUrl (path) {
    const url = new URL(this._parsedBaseUrl)
    if (path) {
      url.pathname = url.pathname.replace(/\/+$/, '') + path
    }
    return url.toString()
  }

  _csrfToken () {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }

  _headers () {
    const headers = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': this._csrfToken()
    }
    if (this._userId) {
      headers['X-User-Id'] = this._userId
    }
    return headers
  }

  async _get (path) {
    const url = this._buildUrl(path)
    const response = await fetch(url, {
      method: 'GET',
      headers: this._headers()
    })
    if (!response.ok) throw new Error(`GET ${path} failed: ${response.status}`)
    return response.json()
  }

  async _post (path, body) {
    const url = this._buildUrl(path)
    const response = await fetch(url, {
      method: 'POST',
      headers: this._headers(),
      body: JSON.stringify(body)
    })
    if (!response.ok) throw new Error(`POST ${path} failed: ${response.status}`)
    return response.json()
  }

  async _patch (path, body) {
    const url = this._buildUrl(path)
    const response = await fetch(url, {
      method: 'PATCH',
      headers: this._headers(),
      body: JSON.stringify(body)
    })
    if (!response.ok) throw new Error(`PATCH ${path} failed: ${response.status}`)
    return response.json()
  }

  async _delete (path) {
    const url = this._buildUrl(path)
    const response = await fetch(url, {
      method: 'DELETE',
      headers: this._headers()
    })
    if (!response.ok) throw new Error(`DELETE ${path} failed: ${response.status}`)
  }

  _removeMarks (threadId) {
    if (!this._editor?._tiptapEditor) return
    const { state, dispatch } = this._editor._tiptapEditor.view
    const markType = state.schema.marks.comment
    if (!markType) return

    const { tr } = state
    let changed = false
    state.doc.descendants((node, pos) => {
      if (node.marks?.some(m => m.type === markType && m.attrs.threadId === threadId)) {
        tr.removeMark(pos, pos + node.nodeSize, markType.create({ threadId }))
        changed = true
      }
    })
    if (changed) dispatch(tr)
  }

  async _deleteWithBody (path, body) {
    const url = this._buildUrl(path)
    const response = await fetch(url, {
      method: 'DELETE',
      headers: this._headers(),
      body: JSON.stringify(body)
    })
    if (!response.ok) throw new Error(`DELETE ${path} failed: ${response.status}`)
  }
}
