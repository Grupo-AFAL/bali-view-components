import { useMemo, useEffect, useRef } from 'react'
import { CommentsExtension } from '@blocknote/core/comments'
import { InMemoryThreadStore } from './InMemoryThreadStore'
import { RESTThreadStore } from './RESTThreadStore'

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
 * @returns {{ extension: Object, threadStore: ThreadStore } | null}
 */
export function useComments ({ commentsUser, commentsUsers, commentsUsersUrl, commentsUrl }) {
  const threadStoreRef = useRef(null)

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

    // Destroy previous store if switching
    if (threadStoreRef.current?.destroy) {
      threadStoreRef.current.destroy()
    }

    const userId = String(commentsUser.id)
    const threadStore = commentsUrl
      ? new RESTThreadStore(userId, commentsUrl)
      : new InMemoryThreadStore(userId, 'editor')

    threadStoreRef.current = threadStore

    // Build the user cache from the static list (if provided)
    const staticUserMap = new Map()
    if (Array.isArray(commentsUsers)) {
      commentsUsers.forEach(u => {
        staticUserMap.set(String(u.id), {
          id: String(u.id),
          username: u.username || u.name || `User ${u.id}`,
          avatarUrl: u.avatarUrl || u.avatar_url || ''
        })
      })
    }

    // Always include the current user
    staticUserMap.set(userId, {
      id: userId,
      username: commentsUser.username || commentsUser.name || `User ${userId}`,
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
                username: u.username || u.name || `User ${u.id}`,
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
          resolved.push({ id: String(uid), username: `User ${uid}`, avatarUrl: '' })
        }
      }

      return resolved
    }

    const extension = CommentsExtension({ threadStore, resolveUsers })

    // Pre-populate the UserStore cache synchronously with all known users
    // so that getUser() returns data on the very first render. Without this,
    // resolved threads crash because BlockNote's Comments component throws
    // when resolvedBy user data is missing from the synchronous snapshot
    // (useUsers → getUser returns undefined before async loadUsers completes).
    for (const [id, user] of staticUserMap) {
      extension.userStore.userCache.set(id, user)
    }

    return { extension, threadStore }
  }, [commentsUser, commentsUsers, commentsUsersUrl, commentsUrl])
}
