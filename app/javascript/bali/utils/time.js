/**
 * Returns a 13 digit timestamp + random number between 1 and 100
 */
export const getTimestamp = () => {
  const randomNumber = Math.floor(Math.random() * 100 + 1)
  return new Date().getTime().toString() + randomNumber
}

/**
 * Utility function used wait until something is loaded
 *
 * @param {*} f Waits until this function evaluates to a truthy value
 * @param {*} timeoutMs timeout in ms
 */
export const waitUntil = async (f, timeoutMs = 2000) => {
  const checkEveryMs = 50

  return new Promise((resolve, reject) => {
    const timeWas = new Date()
    const wait = setInterval(function () {
      const result = f()
      if (result) {
        clearInterval(wait)
        resolve(result)
      } else if (new Date() - timeWas > timeoutMs) {
        clearInterval(wait)
        reject(new Error('Timed out after 2 seconds'))
      }
    }, checkEveryMs)
  })
}

/**
 * Move date into the future by a set number of days
 *
 * @param {*} date Date in string format
 * @param {*} days number of days
 */
export const addDaysToDate = (date, days) => {
  const newDate = new Date(Date.parse(date))
  newDate.setDate(newDate.getDate() + days)

  return newDate
}
