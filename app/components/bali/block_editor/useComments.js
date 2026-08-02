import { useMemo, useEffect, useRef } from 'react'
import { CommentsExtension } from '@blocknote/core/comments'
import { InMemoryThreadStore } from './InMemoryThreadStore'
import { RESTThreadStore } from './RESTThreadStore'

// Omit the key entirely when unset so RESTThreadStore's own default (5000 ms)
// stays the single source of that number. `0` is meaningful -- it turns polling
// off for a single-author document -- so it must survive as a real value.
function pollOptions (interval) {
  return Number.isFinite(interval) ? { pollInterval: interval } : {}
}

/**
 * Hook to initialize BlockNote's comments extension with either a
 * REST-backed ThreadStore (when commentsUrl is provided) or an
 * in-memory ThreadStore (fallback for non-persistent use).
 *
 * @param {Object} options
 * @param {Object} options.commentsUser    - Current user: { id, username, avatarUrl }
 * @param {Array}  options.commentsUsers   - Static user list for resolution
 * @param {string} options.commentsUsersUrl - Remote endpoint for user resolution
 * @param {string} options.commentsUrl     - REST API base URL for thread persistence
 * @param {number} options.commentsPollInterval - Poll period in ms; 0 disables polling
 * @param {Object} options.translations   - Rails-supplied UI strings
 * @returns {{ extension: Object, threadStore: ThreadStore } | null}
 */
export function useComments ({
  commentsUser, commentsUsers, commentsUsersUrl, commentsUrl, commentsPollInterval,
  translations = {}
}) {
  const threadStoreRef = useRef(null)
  // The name shown on a comment whose author id resolves to nothing. It is the
  // one string this hook puts on screen.
  const userFallback = translations.user_fallback ?? 'User %{id}'

  // Clean up polling on unmount
  useEffect(() => {
    return () => {
      if (threadStoreRef.current?.destroy) {
        threadStoreRef.current.destroy()
      }
    }
  }, [])

  return useMemo(() => {
    if (!commentsUser?.id) return null

    const nameFor = (id) => userFallback.replaceAll('%{id}', id)

    // Destroy previous store if switching
    if (threadStoreRef.current?.destroy) {
      threadStoreRef.current.destroy()
    }

    const userId = String(commentsUser.id)
    const threadStore = commentsUrl
      ? new RESTThreadStore(userId, commentsUrl, pollOptions(commentsPollInterval))
      : new InMemoryThreadStore(userId, 'editor')

    threadStoreRef.current = threadStore

    // Build the user cache from the static list (if provided)
    const staticUserMap = new Map()
    if (Array.isArray(commentsUsers)) {
      commentsUsers.forEach(u => {
        staticUserMap.set(String(u.id), {
          id: String(u.id),
          username: u.username || u.name || nameFor(u.id),
          avatarUrl: u.avatarUrl || u.avatar_url || ''
        })
      })
    }

    // Always include the current user
    staticUserMap.set(userId, {
      id: userId,
      username: commentsUser.username || commentsUser.name || nameFor(userId),
      avatarUrl: commentsUser.avatarUrl || commentsUser.avatar_url || ''
    })

    const resolveUsers = async (userIds) => {
      // First, resolve from static list
      const resolved = []
      const missing = []

      for (const uid of userIds) {
        const cached = staticUserMap.get(String(uid))
        if (cached) {
          resolved.push(cached)
        } else {
          missing.push(uid)
        }
      }

      // Fetch missing users from remote endpoint if available
      if (missing.length > 0 && commentsUsersUrl) {
        try {
          const params = new URLSearchParams()
          missing.forEach(id => params.append('ids[]', id))
          const response = await fetch(`${commentsUsersUrl}?${params}`, {
            headers: { Accept: 'application/json' }
          })
          if (response.ok) {
            const users = await response.json()
            for (const u of users) {
              const user = {
                id: String(u.id),
                username: u.username || u.name || nameFor(u.id),
                avatarUrl: u.avatarUrl || u.avatar_url || ''
              }
              staticUserMap.set(user.id, user)
              resolved.push(user)
            }
          }
        } catch (error) {
          console.error('BlockEditor: Failed to resolve comment users:', error)
        }
      }

      // Fallback: return placeholder for any still-missing users
      for (const uid of missing) {
        if (!resolved.find(u => u.id === String(uid))) {
          resolved.push({ id: String(uid), username: nameFor(uid), avatarUrl: '' })
        }
      }

      return resolved
    }

    const extension = CommentsExtension({ threadStore, resolveUsers })

    // Expose the static user map so BlockNoteEditorWrapper can pre-populate
    // the editor's UserStore cache after the editor is created. This prevents
    // crashes when BlockNote renders resolved threads before async user
    // resolution completes (useUsers → getUser returns undefined).
    return { extension, threadStore, staticUserMap }
  }, [commentsUser, commentsUsers, commentsUsersUrl, commentsUrl, commentsPollInterval, userFallback])
}
