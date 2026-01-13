import SuggestionRenderer from 'bali/rich_text_editor/suggestions/renderer'

/**
 * Tiptap suggestion utility
 *
 * https://tiptap.dev/api/utilities/suggestion
 */
export default {
  decorationClass: 'slash-command',
  items: ({ query }) => {
    return [
      {
        title: 'Heading 1',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleHeading({ level: 1 })
            .run()
        }
      },
      {
        title: 'Heading 2',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleHeading({ level: 2 })
            .run()
        }
      },
      {
        title: 'Heading 3',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleHeading({ level: 3 })
            .run()
        }
      },
      {
        title: 'Bulleted list',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleBulletList()
            .run()
        }
      },
      {
        title: 'Ordered list',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleOrderedList()
            .run()
        }
      },
      {
        title: 'Quote',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleBlockquote()
            .run()
        }
      },
      {
        title: 'Code',
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .toggleCodeBlock()
            .run()
        }
      },
      {
        title: 'Table',
        icon: `<svg viewBox="0 0 24 24" class="svg-inline">
                <path d="M21.75 3.75012H2.25C1.83516 3.75012 1.5 4.08528 1.5 4.50012V19.5001C1.5 19.915 1.83516 20.2501 2.25 20.2501H21.75C22.1648 20.2501 22.5 19.915 22.5 19.5001V4.50012C22.5 4.08528 22.1648 3.75012 21.75 3.75012ZM20.8125 8.62512H15.8438V5.43762H20.8125V8.62512ZM20.8125 13.8751H15.8438V10.1251H20.8125V13.8751ZM9.65625 10.1251H14.3438V13.8751H9.65625V10.1251ZM14.3438 8.62512H9.65625V5.43762H14.3438V8.62512ZM3.1875 10.1251H8.15625V13.8751H3.1875V10.1251ZM3.1875 5.43762H8.15625V8.62512H3.1875V5.43762ZM3.1875 15.3751H8.15625V18.5626H3.1875V15.3751ZM9.65625 15.3751H14.3438V18.5626H9.65625V15.3751ZM20.8125 18.5626H15.8438V15.3751H20.8125V18.5626Z" fill="#262626" />
              </svg>`,
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .insertTable({ rows: 3, cols: 3, withHeaderRow: true })
            .run()
        }
      },
      {
        title: 'Image',
        icon: `<svg viewBox="0 0 512 512" class="svg-inline">
                <path fill="currentColor" d="M464 448H48c-26.51 0-48-21.49-48-48V112c0-26.51 21.49-48 48-48h416c26.51 0 48 21.49 48 48v288c0 26.51-21.49 48-48 48zM112 120c-30.928 0-56 25.072-56 56s25.072 56 56 56 56-25.072 56-56-25.072-56-56-56zM64 384h384V272l-87.515-87.515c-4.686-4.686-12.284-4.686-16.971 0L208 320l-55.515-55.515c-4.686-4.686-12.284-4.686-16.971 0L64 336v48z" class=""></path>
              </svg>`,
        command: ({ editor, range }) => {
          editor
            .chain()
            .focus()
            .deleteRange(range)
            .setImage({ src: '/assets/bali/rich_text_editor/javascript/assets/image_placeholder.png' })
            .run()
        }
      }
    ]
      .filter(item => item.title.toLowerCase().startsWith(query.toLowerCase()))
      .slice(0, 10)
  },

  render: SuggestionRenderer({
    popUpOptions: {
      rootOptions: { className: 'slash-commands-dropdown border border-base-200 w-48 [&_.dropdown-item]:cursor-pointer [&_.dropdown-item]:flex [&_.dropdown-item]:items-center [&_.icon]:mr-2' }
    }
  })
}
