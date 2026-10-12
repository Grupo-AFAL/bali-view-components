const API_URL = 'https://maps.googleapis.com/maps/api/js'
const CALLBACK_NAME = '__googleMapsApiOnLoadCallback'
const optionsKeys = ['channel', 'client', 'key', 'language', 'region', 'v']

const defaultTimeout = 10000
let api = null

export default function (options = {}) {
  api =
    api ||
    new Promise((resolve, reject) => {
      // Hook up the on load callback
      window[CALLBACK_NAME] = function () {
        resolve(window.google.maps)
      }

      // Prepare the `script` tag to be inserted into the page
      const scriptElement = document.createElement('script')
      scriptElement.async = true // Load asynchronously to not block rendering
      scriptElement.onerror = function () {
        scriptElement.remove()
        api = null
        reject(new Error('Could not load the Google Maps API'))
      }
      const params = [
        `callback=${CALLBACK_NAME}`,
        'loading=async' // Google Maps recommended async loading parameter
      ]
      optionsKeys.forEach(key => {
        if (options[key]) {
          params.push(`${key}=${options[key]}`)
        }
      })
      if (options.libraries && options.libraries.length) {
        params.push(`libraries=${options.libraries.join(',')}`)
      }
      scriptElement.src = `${options.apiUrl || API_URL}?${params.join('&')}`

      // Insert the `script` tag
      document.body.appendChild(scriptElement)
    })

  // The timeout is the caller's, not the script's: a script still loading when its caller gives
  // up runs once it arrives, removed from the page or not (Chromium and Firefox, measured), so the
  // next call waits for it rather than load a second copy of the API over it. The platform's
  // `TimeoutError`, so a caller can tell it from a script that failed and wait on: the four map
  // controllers do.
  return new Promise((resolve, reject) => {
    const timeoutId = setTimeout(function () {
      reject(new DOMException('Timed out loading the Google Maps API', 'TimeoutError'))
    }, options.timeout || defaultTimeout)

    api.then(resolve, reject).finally(() => clearTimeout(timeoutId))
  })
}
