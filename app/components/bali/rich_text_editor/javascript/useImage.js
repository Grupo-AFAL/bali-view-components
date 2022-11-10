import { get } from '@rails/request.js'

export const imageTargets = ['imagePanel', 'imageGrid']

export default async (controller, _options = {}) => {
  const { default: Image } = await import('@tiptap/extension-image')

  const ImageExtensions = [Image]

  const reloadImages = async () => {
    const response = await get(controller.imagesUrlValue)

    if (response.ok) {
      controller.imageGridTarget.innerHTML = await response.html
    }
  }

  let isOpen = false

  const openImagePanel = () => {
    controller.closeNodeSelect()
    controller.closeTablePanel()
    controller.closeLinkPanel()

    if (!controller.hasImagePanelTarget) return

    isOpen = true
    reloadImages()
    controller.imagePanelTarget.classList.add('is-active')
  }

  const closeImagePanel = () => {
    if (!controller.hasImagePanelTarget) return

    isOpen = false
    controller.imagePanelTarget.classList.remove('is-active')
  }

  const toggleImagePanel = () => {
    if (isOpen) {
      closeImagePanel()
    } else {
      openImagePanel()
    }
  }

  const addImage = event => {
    controller.runCommand('setImage', {
      src: event.target.dataset.sourceUrl
    })
  }

  Object.assign(controller, {
    openImagePanel,
    closeImagePanel,
    toggleImagePanel,
    addImage
  })

  return { ImageExtensions }
}
