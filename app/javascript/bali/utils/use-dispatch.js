const composeEventName = (name, controller, eventPrefix) => {
  let composedName = name
  if (eventPrefix === true) {
    composedName = `${controller.identifier}:${name}`
  } else if (typeof eventPrefix === 'string') {
    composedName = `${eventPrefix}:${name}`
  }
  return composedName
}

const defaultOptions = {
  eventPrefix: true,
  bubbles: true,
  cancelable: true,
  debug: false,
  logger: console
}

class UseDispatch {
  constructor (controller, options = {}) {
    // super(controller, options)

    console.log('UseDispatch', controller, options)

    this.debug = options?.debug ?? defaultOptions.debug
    this.logger = options?.logger ?? defaultOptions.logger
    this.controller = controller
    this.controllerId = controller.element.id || controller.element.dataset.id
    this.targetElement = options?.element || controller.element

    this.eventPrefix = options.eventPrefix ?? defaultOptions.eventPrefix
    this.bubbles = options.bubbles ?? defaultOptions.bubbles
    this.cancelable = options.cancelable ?? defaultOptions.cancelable

    this.enhanceController()
  }

  log = (functionName, args) => {
    if (!this.debug) return

    this.logger.groupCollapsed(
      `%c${this.controller.identifier} %c#${functionName}`,
      'color: #3B82F6',
      'color: unset'
    )
    this.logger.log({
      controllerId: this.controllerId,
      ...args
    })
    this.logger.groupEnd()
  }

  dispatch = (eventName, detail = {}) => {
    const {
      controller,
      targetElement,
      eventPrefix,
      bubbles,
      cancelable,
      log
    } = this

    // includes the emitting controller in the event detail
    Object.assign(detail, { controller })

    const eventNameWithPrefix = composeEventName(
      eventName,
      this.controller,
      eventPrefix
    )

    // creates the custom event
    const event = new CustomEvent(eventNameWithPrefix, {
      detail,
      bubbles,
      cancelable
    })

    // dispatch the event from the given element or by default from the root element of the controller
    targetElement.dispatchEvent(event)

    log('dispatch', {
      eventName: eventNameWithPrefix,
      detail,
      bubbles,
      cancelable
    })

    return event
  }

  enhanceController () {
    Object.assign(this.controller, { dispatch: this.dispatch })
  }
}

export default (controller, options = {}) => {
  return new UseDispatch(controller, options)
}
