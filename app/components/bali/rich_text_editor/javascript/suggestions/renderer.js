import tippy from 'tippy.js'
import PopUpListComponent from './popup_list_component.js'

export default ({ popUpOptions } = {}) => {
  return () => {
    const component = new PopUpListComponent(popUpOptions)
    let popup

    return {
      onStart: function ({ items, command, clientRect }) {
        popup = tippy('body', {
          getReferenceClientRect: clientRect,
          appendTo: () => document.body,
          allowHTML: true,
          content: component.render(),
          showOnCreate: true,
          interactive: true,
          trigger: 'manual',
          placement: 'bottom-start',
          arrow: false
        })

        this.onUpdate({ items, command, clientRect })
      },

      onUpdate ({ items, command, clientRect }) {
        component.updateProps({ items, command })
        component.render()
        popup[0].setProps({ getReferenceClientRect: clientRect })
      },

      onKeyDown ({ event }) {
        if (event.key === 'Escape') {
          popup[0].hide()
          return true
        } else if (event.key === 'Enter') {
          component.selectActiveItem()
          return true
        } else if (event.key === 'ArrowUp') {
          component.goUp()
          return true
        } else if (event.key === 'ArrowDown') {
          component.goDown()
          return true
        }
      },

      onExit () {
        popup[0].destroy()
        component.destroy()
      }
    }
  }
}
