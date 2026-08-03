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

// The only two shapes BlockNote's user store has had: a plain `userCache` Map up
// to @blocknote 0.46, a `setUser` method from 0.52. Reading is `getUser` in both.
function writeUser (store, user) {
  if (typeof store.setUser === 'function') return store.setUser(user)
  store.userCache?.set(user.id, user)
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
    const placeholderUser = (id) => ({
      id: String(id), username: nameFor(id), avatarUrl: ''
    })

    // Destroy previous store if switching
    if (threadStoreRef.current?.destroy) {
      threadStoreRef.current.destroy()
    }

    const userId = String(commentsUser.id)
    const threadStore = commentsUrl
      ? new RESTThreadStore(userId, commentsUrl, pollOptions(commentsPollInterval))
      : new InMemoryThreadStore(userId, 'editor')

    threadStoreRef.current = threadStore

    // BlockNote reads a thread's users *synchronously* while rendering it and
    // throws when an id is not in the user store yet -- and that throw escapes
    // into React's render, so it takes the whole editor down, not just the
    // comments sidebar. Every path that fills the store is async: resolveUsers
    // returns a promise and RESTThreadStore polls on top of it. A thread from
    // anyone outside the static `users:` list -- someone who left, or the normal
    // case when the host resolves through `users_url` -- would race that render
    // and lose.
    //
    // So on every change to the thread list: start the real load, then write a
    // placeholder for whatever is still unknown. loadUsers() registers the ids as
    // in flight before it awaits, so the placeholder does not cancel the fetch;
    // it just guarantees the synchronous read finds *something*, and the real
    // name replaces it when it lands.
    //
    // Registering here is what makes the ordering hold: this is the line after
    // the store is constructed, before any reference to it escapes this function,
    // so this subscriber always runs ahead of the one BlockNote's comments
    // extension adds. `userStore` stays empty until BlockNoteEditorWrapper hands
    // it over -- the store does not exist until the editor is created.
    const userStore = { current: null }

    const seedUsers = (threads) => {
      const store = userStore.current
      if (!store) return

      const ids = new Set()
      for (const thread of threads.values()) {
        if (thread.resolvedBy) ids.add(String(thread.resolvedBy))
        thread.comments?.forEach(c => c.userId && ids.add(String(c.userId)))
      }

      const unknown = [...ids].filter(id => !store.getUser(id))
      if (unknown.length === 0) return

      store.loadUsers(unknown)
      unknown.forEach(id => writeUser(store, placeholderUser(id)))
    }

    threadStore.subscribe(seedUsers)

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
          resolved.push(placeholderUser(uid))
        }
      }

      return resolved
    }

    const extension = CommentsExtension({ threadStore, resolveUsers })

    // The user store belongs to the extension and only exists once the editor
    // has been created, so BlockNoteEditorWrapper hands it over. Seeding the
    // static list here is not about the crash -- seedUsers already covers that
    // -- it is so the common case shows real names instead of flashing a
    // placeholder first. getThreads() catches whatever landed while the store
    // did not exist yet.
    const attachUserStore = (store) => {
      userStore.current = store
      staticUserMap.forEach(user => writeUser(store, user))
      seedUsers(threadStore.getThreads())
    }

    return { extension, threadStore, attachUserStore }
  }, [commentsUser, commentsUsers, commentsUsersUrl, commentsUrl, commentsPollInterval, userFallback])
}
