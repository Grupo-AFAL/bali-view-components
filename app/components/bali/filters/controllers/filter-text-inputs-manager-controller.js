import { Controller } from '@hotwired/stimulus'

export class FilterTextInputsManagerController extends Controller {
  static targets = ['inputsContainer']
  static values = {
    inputName: { type: String, default: '' },
    type: { type: String, default: 'text' }
  }

  add = () => {
    const input = this.createInput()
    const inputControl = this.createControlElement()

    const button = this.createRemoveButton()
    const buttonControl = this.createControlElement()

    const container = document.createElement('div')
    container.classList.add('field')
    container.classList.add('has-addons')
    container.style.height = 'min-content'

    inputControl.appendChild(input)
    buttonControl.appendChild(button)

    container.appendChild(inputControl)
    container.appendChild(buttonControl)

    this.inputsContainerTarget.appendChild(container)
  }

  remove = (event) => {
    event.preventDefault()
    event.stopPropagation()

    event.target.closest('.field.has-addons').remove()
  }

  createInput = () => {
    const element = document.createElement('input')
    element.classList.add('input')
    element.setAttribute('type', this.typeValue)
    element.setAttribute('name', this.inputNameValue)

    return element
  }

  createControlElement = () => {
    const element = document.createElement('div')
    element.classList.add('control')

    return element
  }

  createRemoveButton = () => {
    const element = document.createElement('button')
    element.classList.add('button')
    element.setAttribute('type', 'button')
    element.setAttribute('data-action', 'filter-text-inputs-manager#remove')
    element.innerHTML = '&times;'

    return element
  }
}
