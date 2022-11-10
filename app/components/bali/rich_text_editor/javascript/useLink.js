const defaultOptions = {
  openOnClick: false
}

export const linkTargets = ['linkPanel', 'linkInput']

export default async (controller, options = {}) => {
  const { default: Link } = await import('@tiptap/extension-link')

  const { openOnClick } = Object.assign({}, defaultOptions, options)

  const LinkExtensions = [
    Link.configure({
      openOnClick
    })
  ]

  const closeLinkPanel = () => {
    if (!controller.hasLinkPanelTarget) return

    controller.linkPanelTarget.classList.remove('is-active')
  }

  const openLinkPanel = () => {
    controller.closeNodeSelect()
    controller.closeTablePanel()
    controller.closeImagePanel()

    const link = controller.editor.getAttributes('link')
    controller.linkInputTarget.innerHTML = link.href || ''
    controller.linkInputTarget.focus()
  }

  const saveLinkUrl = event => {
    if (event.key !== 'Enter') return
    const url = event.target.innerHTML

    if (url === '') {
      controller.editor
        .chain()
        .focus()
        .extendMarkRange('link')
        .unsetLink()
        .run()
    } else {
      controller.editor
        .chain()
        .focus()
        .extendMarkRange('link')
        .setLink({ href: event.target.innerHTML, target: '_blank' })
        .run()
    }

    controller.linkInputTarget.innerHTML = ''
  }

  // TODO: Create PageLink extension to be able to store reference to the page.
  const savePageLink = event => {
    const { url } = event.target.dataset

    controller.editor
      .chain()
      .focus()
      .extendMarkRange('link')
      // TODO: Make it work with Turbo. So it doesn't do a full page reload
      //       every time an internal link is clicked
      .setLink({ href: url, target: '_self' })
      .run()
  }

  Object.assign(controller, {
    closeLinkPanel,
    openLinkPanel,
    saveLinkUrl,
    savePageLink
  })

  return { LinkExtensions }
}
