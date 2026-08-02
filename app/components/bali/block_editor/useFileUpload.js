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

// Rails ships the sentence with its placeholders intact; the numbers only exist
// in the browser, so they are substituted here.
function interpolate (template, values) {
  return Object.entries(values).reduce(
    (text, [key, value]) => text.replaceAll(`%{${key}}`, value),
    template
  )
}

// English is what a host gets when it wires this controller up by hand instead
// of rendering the component; through the component, Rails always supplies these.
// Only the three strings that reach the DOM are here -- the two that merely
// `throw` are developer signals and stay in English on purpose.
const FALLBACKS = {
  upload_not_configured: 'File uploads are not configured',
  upload_too_large: 'File is too large (%{size} MB). Maximum allowed is %{max} MB.',
  upload_failed: 'Upload failed (%{status})'
}

export function useFileUpload (uploadUrl, container = null, translations = {}) {
  return useCallback(async (file) => {
    const t = (key, values = {}) => interpolate(translations[key] ?? FALLBACKS[key], values)

    if (!uploadUrl) {
      const message = t('upload_not_configured')
      showUploadError(message, container)
      throw new Error(message)
    }

    if (file.size > MAX_UPLOAD_SIZE) {
      const message = t('upload_too_large', {
        size: (file.size / (1024 * 1024)).toFixed(1),
        max: Math.round(MAX_UPLOAD_SIZE / (1024 * 1024))
      })
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
      let message = t('upload_failed', { status: response.status })
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
  }, [uploadUrl, container, translations])
}
