import { useCallback } from 'react'
import { MAX_UPLOAD_SIZE } from './constants'

function showUploadError (message) {
  const container = document.querySelector('[data-controller="block-editor"]')
  if (!container) return

  const toast = document.createElement('div')
  toast.className = 'alert alert-error shadow-lg fixed bottom-4 right-4 z-50 max-w-md animate-fade-in'
  toast.setAttribute('role', 'alert')
  toast.textContent = message
  document.body.appendChild(toast)
  setTimeout(() => toast.remove(), 5000)
}

export function useFileUpload (uploadUrl) {
  return useCallback(async (file) => {
    if (!uploadUrl) {
      showUploadError('File uploads are not configured')
      throw new Error('File uploads are not configured')
    }

    if (file.size > MAX_UPLOAD_SIZE) {
      const maxMB = Math.round(MAX_UPLOAD_SIZE / (1024 * 1024))
      const fileMB = (file.size / (1024 * 1024)).toFixed(1)
      const message = `File is too large (${fileMB} MB). Maximum allowed is ${maxMB} MB.`
      showUploadError(message)
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
      showUploadError(message)
      throw new Error(message)
    }

    const data = await response.json()
    if (data.url && (data.url.startsWith('/') || /^https?:\/\//i.test(data.url))) {
      return data.url
    }
    throw new Error('Invalid URL returned from upload endpoint')
  }, [uploadUrl])
}
