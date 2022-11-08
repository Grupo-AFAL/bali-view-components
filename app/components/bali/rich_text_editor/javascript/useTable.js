import Table from '@tiptap/extension-table'
import TableRow from '@tiptap/extension-table-row'
import TableCell from '@tiptap/extension-table-cell'
import TableHeader from '@tiptap/extension-table-header'

const defaultOptions = {
  resizable: false
}

export const tableTargets = ['tablePanel', 'tableModifier']

export default (controller, options = {}) => {
  const { resizable } = Object.assign({}, defaultOptions, options)

  const TableExtensions = [
    Table.configure({
      resizable
    }),
    TableRow,
    TableCell,
    TableHeader
  ]

  const runTableCommand = (event, name) => {
    if (!controller.editor.isActive('table')) {
      return event.stopPropagation()
    }

    controller.runCommand(name)
  }

  const insertTable = () => {
    controller.runCommand('insertTable', {
      rows: 3,
      cols: 3,
      withHeaderRow: true
    })
  }

  const addColumnBefore = e => runTableCommand(e, 'addColumnBefore')
  const addColumnAfter = e => runTableCommand(e, 'addColumnAfter')
  const addRowBefore = e => runTableCommand(e, 'addRowBefore')
  const addRowAfter = e => runTableCommand(e, 'addRowAfter')
  const deleteColumn = e => runTableCommand(e, 'deleteColumn')
  const deleteRow = e => runTableCommand(e, 'deleteRow')

  const updateTableModifiers = () => {
    const tableIsActive = controller.editor.isActive('table')

    controller.tableModifierTargets.forEach(modifier => {
      tableIsActive
        ? modifier.classList.remove('disabled')
        : modifier.classList.add('disabled')
    })
  }

  const openTablePanel = () => {
    controller.closeNodeSelect()
    controller.closeLinkPanel()
    controller.closeImagePanel()
  }

  const closeTablePanel = () => {
    if (!controller.hasTablePanelTarget) return

    controller.tablePanelTarget.classList.remove('is-active')
  }

  Object.assign(controller, {
    insertTable,
    addColumnBefore,
    addColumnAfter,
    addRowBefore,
    addRowAfter,
    deleteColumn,
    deleteRow,
    updateTableModifiers,
    openTablePanel,
    closeTablePanel
  })

  return { TableExtensions }
}
