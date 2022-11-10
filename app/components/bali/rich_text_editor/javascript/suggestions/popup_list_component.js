import throttle from 'lodash.throttle'

const createRoot = ({ className } = {}) => {
  const div = document.createElement('div')
  div.classList.add('dropdown-content', className)
  return div
}

const createItem = (list, index, item, classNames = '') => {
  const div = document.createElement('div')
  div.classList.add('dropdown-item', classNames)

  if (item.icon) {
    div.innerHTML = `<span class='icon'>${item.icon}</span><span>${item.title}</span>`
  } else {
    div.innerHTML = item.title
  }

  div.addEventListener('mousemove', () => list.throttledUpdateActiveItem(index))
  div.addEventListener('mousedown', () => list.selectItem(index))
  return div
}

export default class PopUpListComponent {
  constructor ({ rootOptions } = {}) {
    this.selectedIndex = 0
    this.items = []
    this.command = () => {}
    this.element = createRoot(rootOptions)
  }

  render () {
    this.element.innerHTML = ''
    this.items.forEach((item, index) => {
      const classNames = index === this.selectedIndex ? 'is-active' : 'inactive'
      this.element.appendChild(createItem(this, index, item, classNames))
    })
    return this.element
  }

  updateProps ({ items, command }) {
    this.items = items
    this.command = command
  }

  throttledUpdateActiveItem = throttle(this.updateActiveItem, 100)

  selectItem (index) {
    const { url, title, command } = this.items[index]
    this.command({ id: url, url, label: title, command })
  }

  selectActiveItem () {
    this.selectItem(this.selectedIndex)
  }

  updateActiveItem (index) {
    this.selectedIndex = index
    this.render()
  }

  goUp () {
    const newSelectedIndex =
      (this.selectedIndex + this.items.length - 1) % this.items.length
    this.updateActiveItem(newSelectedIndex)
  }

  goDown () {
    const newSelectedIndex = (this.selectedIndex + 1) % this.items.length
    this.updateActiveItem(newSelectedIndex)
  }

  destroy () {
    this.element.remove()
  }
}
