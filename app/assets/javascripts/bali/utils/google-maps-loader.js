const API_URL = 'https://maps.googleapis.com/maps/api/js'
const CALLBACK_NAME = '__googleMapsApiOnLoadCallback'
const optionsKeys = ['channel', 'client', 'key', 'language', 'region', 'v']

const defaultTimeout = 10000
let api = null
let apiOptions = null
const warnedKeys = new Set()

export default function (options = {}) {
  if (api) {
    warnAboutIgnoredOptions(options)
  } else {
    apiOptions = options
    api = new Promise((resolve, reject) => {
      window[CALLBACK_NAME] = function () {
        resolve(window.google.maps)
      }

      const scriptElement = document.createElement('script')
      scriptElement.async = true
      scriptElement.onerror = function () {
        scriptElement.remove()
        api = null
        warnedKeys.clear()
        reject(new Error('Could not load the Google Maps API'))
      }
      const params = new URLSearchParams({
        callback: CALLBACK_NAME,
        loading: 'async'
      })
      optionsKeys.forEach(key => {
        if (options[key]) {
          params.set(key, options[key])
        }
      })
      if (options.libraries && options.libraries.length) {
        params.set('libraries', options.libraries.join(','))
      }
      scriptElement.src = `${options.apiUrl || API_URL}?${params}`
      document.body.appendChild(scriptElement)
    })
  }

  // Every call imports the libraries it asks for, so a later call gets its own into the API the
  // first one loaded. The first call's also go in the script URL, which has them ready ~135 ms
  // sooner, and importing one the script already loaded resolves in the same millisecond (both
  // measured, 3.66).
  const libraries = options.libraries || []
  const loaded = api.then(maps => Promise.all(libraries.map(name => maps.importLibrary(name))).then(() => maps))

  // 0 is no deadline, as for XHR: setTimeout would read it as "at once".
  const timeout = options.timeout ?? defaultTimeout
  if (timeout === 0) return loaded

  // The timeout is the caller's, not the script's: a script still loading when its caller gives
  // up runs once it arrives, removed from the page or not (Chromium and Firefox, measured), so the
  // next call waits for it rather than load a second copy of the API over it. The platform's
  // `TimeoutError`, so a caller can tell it from a script that failed and wait on: the four map
  // controllers do.
  return new Promise((resolve, reject) => {
    const timeoutId = setTimeout(function () {
      reject(new DOMException('Timed out loading the Google Maps API', 'TimeoutError'))
    }, timeout)

    loaded.then(resolve, reject).finally(() => clearTimeout(timeoutId))
  })
}

function warnAboutIgnoredOptions (options) {
  optionsKeys.forEach(key => {
    if (!options[key] || options[key] === apiOptions[key] || warnedKeys.has(key)) return

    warnedKeys.add(key)
    console.warn(`The Google Maps API loads once per page, with the first call's options: this call's \`${key}\` is ignored.`)
  })
}
