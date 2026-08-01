import { useCallback } from 'react'
import { MAX_UPLOAD_SIZE } from './constants'

// The toast belongs to the editor whose upload failed, so it is appended INSIDE
// that editor's container (`.block-editor-component`, already `position: relative`)
// rather than to <body>.
//
// The previous version did `document.querySelector('[data-controller="block-editor"]')`
// and appended to <body>, which was wrong twice over. The selector is an exact
// attribute match, so it found nothing the moment a host added a second controller
// to the same element (`data-controller="block-editor analytics"`) and the error
// vanished silently. And with two editors on one page it resolved to whichever
// came first in the document regardless of which one failed, so two `position: fixed`
// toasts landed on the same corner, stacked, and the user could not tell which
// editor rejected their file.
function showUploadError (message, container) {
  const host = container ?? document.querySelector('[data-controller~="block-editor"]')
  if (!host) return

  const toast = document.createElement('div')
  toast.className = 'alert alert-error shadow-lg absolute bottom-4 right-4 max-w-md animate-fade-in block-editor-upload-toast'
  toast.setAttribute('role', 'alert')
  toast.textContent = message
  host.appendChild(toast)
  setTimeout(() => toast.remove(), 5000)
}

export function useFileUpload (uploadUrl, container = null) {
  return useCallback(async (file) => {
    if (!uploadUrl) {
      showUploadError('File uploads are not configured', container)
      throw new Error('File uploads are not configured')
    }

    if (file.size > MAX_UPLOAD_SIZE) {
      const maxMB = Math.round(MAX_UPLOAD_SIZE / (1024 * 1024))
      const fileMB = (file.size / (1024 * 1024)).toFixed(1)
      const message = `File is too large (${fileMB} MB). Maximum allowed is ${maxMB} MB.`
      showUploadError(message, container)
      throw new Error(message)
    }

    const formData = new FormData()
    formData.append('file', file)

    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    if (!csrfMeta) {
      throw new Error('CSRF token meta tag not found. Ensure csrf_meta_tags is in your layout.')
    }

    const response = await fetch(uploadUrl, {
      method: 'POST',
      body: formData,
      headers: { 'X-CSRF-Token': csrfMeta.content }
    })

    if (!response.ok) {
      let message = `Upload failed (${response.status})`
      try {
        const err = await response.json()
        if (err.error) message = err.error
      } catch { /* response wasn't JSON, use default */ }
      showUploadError(message, container)
      throw new Error(message)
    }

    const data = await response.json()
    if (data.url && (data.url.startsWith('/') || /^https?:\/\//i.test(data.url))) {
      return data.url
    }
    throw new Error('Invalid URL returned from upload endpoint')
  }, [uploadUrl, container])
}
