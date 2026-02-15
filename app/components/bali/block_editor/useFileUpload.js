import { useCallback } from 'react'
import { MAX_UPLOAD_SIZE } from './constants'

export function useFileUpload (imagesUrl) {
  return useCallback(async (file) => {
    if (!imagesUrl) throw new Error('File uploads are not configured')

    if (file.size > MAX_UPLOAD_SIZE) {
      throw new Error('File size exceeds maximum of 10MB')
    }

    const formData = new FormData()
    formData.append('file', file)

    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    if (!csrfMeta) {
      throw new Error('CSRF token meta tag not found. Ensure csrf_meta_tags is in your layout.')
    }

    const response = await fetch(imagesUrl, {
      method: 'POST',
      body: formData,
      headers: { 'X-CSRF-Token': csrfMeta.content }
    })

    if (!response.ok) throw new Error('Upload failed')

    const data = await response.json()
    if (data.url && (data.url.startsWith('/') || /^https?:\/\//i.test(data.url))) {
      return data.url
    }
    throw new Error('Invalid URL returned from upload endpoint')
  }, [imagesUrl])
}
