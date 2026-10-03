import { paintedContrast } from '../support/painted_contrast'
import { BALI_THEMES, THEMES } from '../support/themes'

const AA = 4.5
const NON_TEXT = 3
const GREY = '[class*="text-base-content/"]'
const appOrigin = new URL(Cypress.config('baseUrl')).origin

// A transition never repeats forever, and the frames a theme switch leaves running are all
// transitions. An animation that does — Frame's spinner, the skeleton AppLayout's closed drawer
// holds — never settles, so waiting on the whole document would wait forever.
const transitions = doc => doc.getAnimations()
  .filter(animation => animation.playState === 'running' && animation.effect.getComputedTiming().iterations !== Infinity)

// Every target of a page, on one theme: [what, selector, how many the page renders, and the
// pseudo-element that paints it when the element itself does not — a `::placeholder`, or the
// `::after` BlockNote writes its placeholder on]. A page is a Lookbook preview, or the dummy
// app's own when it starts with `/`; `stub` is what has to be answered before the page loads,
// and `open` what has to happen before the text shows.
const guard = ({ page, stub, open, targets, theme, floor }) => {
  if (stub) stub()
  cy.visit(page.startsWith('/') ? `${appOrigin}${page}` : `/bali/${page}`)
  if (open) open()
  cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

  cy.get('body').should(($body) => {
    expect(transitions($body[0].ownerDocument), 'transitions settled').to.have.length(0)

    targets.forEach(([what, selector, count, pseudo]) => {
      const elements = [...$body[0].querySelectorAll(selector)]
      expect(elements, `${page}: every ${what}`).to.have.length(count)
      elements.forEach((el) => {
        const generated = () => el.ownerDocument.defaultView.getComputedStyle(el, pseudo).content.replace(/^"|"$/g, '')
        const text = pseudo ? el.getAttribute('placeholder') ?? generated() : el.textContent.trim()
        expect(paintedContrast(el, { pseudo }), `${theme}: ${what} ${text ? `"${text}"` : '(no text)'}`).to.be.at.least(floor)
      })
    })
  })
}

// DocumentEditor's comments panel on one thread. The thread store asks for its threads as the
// editor loads; the reaction is what makes BlockNote draw the add-reaction chip, and with no
// mark left in the document the excerpt says the original content was deleted.
const COMMENTED = {
  page: 'document_editor/default',
  stub: () => {
    const at = '2026-07-01T12:00:00Z'
    const body = [{ id: 'b1', type: 'paragraph', props: {}, content: [{ type: 'text', text: 'Please check the numbers.', styles: {} }], children: [] }]
    const reactions = [{ emoji: '👍', created_at: at, user_ids: ['2'] }]
    cy.intercept('GET', /\/block_editor_comments\?/, [
      { id: 't1', created_at: at, updated_at: at, comments: [{ id: 'c1', user_id: '1', created_at: at, updated_at: at, reactions, body }] }
    ])
  },
  open: () => cy.get('[data-action*="document-editor#toggleComments"]:visible').first().click()
}

// The text a component mutes is `base-content` at an alpha, composited over the
// surface it lands on. Shipped from `/30` to `/60`, it measured as low as
// 1.86:1 against AA's 4.5 (#1233, #1234, #1248, #1256), and no one theme showed all of
// it: `light` passed the timeline's `/60` and `dark` the date's `/50`. Hence every
// theme, and the base-200 cards of the progress preview, where only the labels are
// measured as text: a glyph there paints on its marker's `::before` disc, which this
// guard does not hand to `paintedContrast` (the outline guard below does, as `under`).
// StatCard's cells include an emphasised one, whose primary tint took `/60` down
// to 3.83:1 on `afal`.
//
// Titles and glyphs are collected by their base-content grey: the current
// step's `primary` pair is the theme's own, not measured against AA here (#1221).
describe('muted text contrast', () => {
  const FOOTER = [
    ['section title', '.footer-title', 3],
    ['description', 'aside > p', 1],
    ['copyright', '.footer + div > p', 1]
  ]

  // preview → [what, selector, how many the preview renders]
  const PREVIEWS = {
    'workflow_steps/default': [
      ['title', '.workflow-step-title', 7],
      ['grey circle', `.workflow-step-circle${GREY}`, 2],
      ['assignee', '.workflow-step-assignee', 5],
      ['date', '.workflow-step-date', 4],
      ['comment', '.workflow-step-comment', 4]
    ],
    'workflow_steps/progress': [
      ['label', `.workflow-steps-progress-rail .workflow-step-title${GREY}`, 21],
      ['grey glyph', `:not(.card) > .workflow-steps-progress-rail .workflow-step-circle${GREY}`, 8]
    ],
    'timeline/states': [
      ['timestamp', 'li > .timeline-end:not(.timeline-content-box)', 4],
      ['pending heading', `.timeline-content-box > p${GREY}`, 1]
    ],
    'timeline/tracking': [
      ['timestamp', '.timeline-content-box > p.font-semibold + p', 3],
      ['pending heading', `.timeline-content-box > p.font-semibold${GREY}`, 2]
    ],
    // The third subtitle wraps a `text-info` paragraph: its grey paints no glyph.
    'list/default': [
      ['subtitle', `.list-row ${GREY}:not(:has([class*="text-"]))`, 2]
    ],
    'page_header/with_subtitle_as_param': [
      ['subtitle', '.page-header-component .subtitle', 1]
    ],
    'form/file/default': [
      ['file name', '[data-file-input-target="value"]', 1]
    ],
    'form/range/with_ticks': [
      ['tick', `input.range ~ ${GREY} > span`, 11]
    ],
    'stat_card/cells_in_card': [
      ['label', 'p:has(+ p.text-3xl)', 6],
      ['note', 'p.text-3xl + p', 6]
    ],
    // Two sidebar surfaces: expandable groups sit on base-200.
    'side_menu/default': [
      ['group label', '.menu-label', 2]
    ],
    'side_menu/expandable_groups': [
      ['group label', '.menu-label', 2]
    ],
    'document_page/with_panels': [
      ['contents heading', '[data-document-page-target="tocPanel"] h3', 1],
      ['contents link', '.bn-toc-link', 12]
    ],
    'filters/with_applied_tags': [
      ['caption', '.applied-filters > span:first-child', 1],
      ['operator', '.applied-filters .badge > span:nth-child(2)', 2]
    ],
    // The search sits inside a `label.input`, whose placeholder daisyUI paints; the
    // inputs of simple_filters and the text area carry `.input`/`.textarea` themselves.
    'data_table/with_search': [
      ['search placeholder', '[data-filters-target="searchInput"]', 1, '::placeholder']
    ],
    'data_table/with_simple_filters': [
      ['filter label', '[id^="simple-filter-"][id$="-label"]', 5],
      ['range dash', 'input[type="number"] + span.text-xs', 1],
      ['placeholder', 'input.input[placeholder]:not(.hidden)', 4, '::placeholder']
    ],
    'form/text_area/default': [
      ['placeholder', 'textarea.textarea', 1, '::placeholder']
    ],
    'direct_upload/basic_usage': [
      ['drop zone line', '[data-direct-upload-target="dropzone"] > p', 4]
    ],
    'direct_upload/with_existing_file': [
      ['file size', '[data-direct-upload-target="existingFiles"] .text-xs', 1]
    ],
    // The selected row is tinted `primary/5`: its subtitle and date are measured over it.
    // Only the server's first five rows: infinite scroll keeps appending pages while the
    // guard waits, 15 or 20 rows by the time it measures.
    'split_view/with_selection': [
      ['count', '[data-testid="list-count"]', 1],
      ['subtitle and date', `.split-view-item:nth-child(-n+5) ${GREY}`, 10],
      ['loading line', '.split-view-sentinel', 1]
    ],
    'widget/default?pattern=trend': [
      ['view-all link', '.page-header-component a.link', 1],
      ['trend period', '.bali-widget-body span[aria-hidden="true"]:not(.icon-component) + span', 1]
    ],
    // One row this week against one the week before: no change, which is muted too. The grey
    // is what says it is flat: should `count` stop applying (#843, after a reload), the preview
    // draws its default five-row rise, which is red, and the count fails instead of measuring it.
    'widget/default?pattern=trend&count=1': [
      ['flat trend', `.bali-widget-body ${GREY} > span[aria-hidden="true"]:not(.icon-component)`, 1]
    ],
    'widget/default?pattern=list': [
      ['row subtitle', '.list-row p.text-xs', 3]
    ],
    'widget/default?pattern=list&count=0': [
      ['empty message', '.bali-widget-detail > p', 1]
    ],
    // daisyUI's `.stat-title` paints the hero's title at /60.
    'widget/default?size=small&pattern=value': [
      ['hero title', '.stat-title', 1]
    ],
    'qr_scanner/default': [
      ['hint', '.qr-scanner-hint', 1]
    ],
    'stepper/with_sublabels': [
      ['sublabel', '.step-sublabel', 3]
    ],
    'chat/bubbles': [
      ['timestamp', '.chat-header time', 2]
    ],
    // The default bubble; the primary one is measured on its own below.
    'chat/typing_indicator?show_label=true': [
      ['typing label', '#typing-visible .chat-bubble span.text-xs', 1]
    ],
    'widget_grid/default': [
      ['edit hint', '[data-controller~="bali-widget-grid-edit-mode"] > div:first-child > p', 1]
    ],
    'empty_state/default': [
      ['description', '.empty-state-component p.mt-1', 1]
    ],
    'info_level/default': [
      ['heading', '.level-item .heading', 3]
    ],
    'form/slim_select/placeholder': [
      ['placeholder', '.ss-placeholder', 1]
    ],
    // daisyUI paints the help text, `.fieldset-label`, and a `.table`'s thead and tfoot at
    // `/60` from @layer utilities: 4.04:1 on `afal` (#1281).
    'form/text/with_external_error': [
      ['help text', 'p.fieldset-label[id$="_help"]', 2]
    ],
    'data_table/default': [
      ['column header', 'table.table thead th', 4]
    ],
    'data_table/with_column_selector': [
      ['totals row', 'table.table tfoot :is(td, th)', 3]
    ],
    'form/dynamic_fields/table': [
      ['column header', 'table.table thead th', 3]
    ],
    // daisyUI's `.footer-title` is at `opacity: .6`: on `neutral` it read 4.15:1 on `afal-dark`.
    // The two colours that are a theme's own pair are measured below, on Bali's themes.
    'footer/default?color=neutral': FOOTER,
    'footer/default?color=base': FOOTER,
    // The `·` between the footer's figures is decoration and keeps a colour of its own.
    'gantt/default': [
      ['monospaced figure', '.bali-gantt .font-mono', 53],
      ['caps label', '.bali-gantt .uppercase', 13],
      ['legend label', '.bali-gantt .font-sans', 5],
      ['search placeholder', '.bali-gantt input[placeholder]', 1, '::placeholder']
    ],
    '/dashboard_widgets/edit': [
      ['picker note', 'form p.text-sm', 1]
    ]
  }

  // The text that only shows once something is opened or typed.
  const OPENED = [
    // A `<table class="table">` written by hand, the way host views write theirs: nothing of
    // Bali's on its thead or its tfoot.
    {
      page: 'status/in_table',
      opened: 'a tfoot written by hand',
      open: () => cy.get('table.table').then(($table) => {
        $table[0].insertAdjacentHTML('beforeend', '<tfoot><tr><td>2 scenarios</td><td></td></tr></tfoot>')
      }),
      targets: [['column header', 'table.table thead th', 2], ['totals row', 'table.table tfoot td:first-child', 1]]
    },
    {
      page: 'side_menu/collapsible',
      opened: 'the rail collapsed and a flyout open',
      open: () => {
        cy.viewport(1280, 800)
        cy.get('button[data-action="side-menu#toggleCollapse"]').filter(':visible').first().click()
        cy.get('.side-menu-component').should('have.class', 'is-collapsed')
        cy.get('.side-menu-collapsed-flyout [data-side-menu-flyout-target="trigger"]').first().focus()
      },
      targets: [['flyout title', '.side-menu-collapsed-flyout:focus-within li.menu-title', 1]]
    },
    {
      page: 'side_menu/with_menu_switcher',
      opened: 'the switcher open',
      open: () => cy.get('.menu-switcher-trigger').click(),
      targets: [['menu subtitle', '.side-menu-component--menu-switch-component p.text-xs', 4]]
    },
    {
      page: 'command/default',
      opened: 'the palette open',
      open: () => {
        cy.get('.bali-command-trigger').click()
        cy.get('[data-command-target="panel"]').should('be.visible')
      },
      targets: [
        ['trigger', '.bali-command-trigger', 1],
        ['group heading', '.cmd-group', 4],
        ['row meta', '.cmd-row-meta', 13],
        ['footer hint', '.cmd-panel > :last-child > span:not(.flex-1)', 4],
        ['placeholder', 'input.cmd-input', 1, '::placeholder']
      ]
    },
    {
      page: 'command/default',
      opened: 'a query that matches nothing',
      open: () => {
        cy.get('.bali-command-trigger').click()
        cy.get('input.cmd-input').type('zzqx')
        cy.get('[data-command-target="noResults"]').should('be.visible')
      },
      targets: [['no-results subtitle', '[data-command-target="noResults"] > .text-xs', 1]]
    },
    {
      page: 'document_editor/default',
      opened: 'the contents, the history and a version open',
      open: () => {
        const versions = [1, 2].map(id => ({
          id, version_number: id, summary: `Change ${id}`, author_name: 'Demo User', created_at: '2026-07-01T12:00:00Z'
        }))
        cy.intercept('GET', /\/lookbook$/, { headers: { 'Content-Type': 'application/json' }, body: versions })
        cy.intercept('GET', /\/lookbook\/\d+$/, {
          id: 1,
          version_number: 1,
          content: [{ id: 'stub', type: 'paragraph', props: {}, content: [{ type: 'text', text: 'STUB', styles: {} }], children: [] }]
        })
        cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor').should('exist')
        // An edit is what writes the save status.
        cy.get('[data-document-editor-target="editorArea"]').trigger('input')
        cy.get('[data-action*="document-editor#toggleToc"]:visible').first().click()
        cy.get('[data-action*="document-editor#toggleHistory"]:visible').first().click()
        cy.get('[data-action*="previewVersion"]:visible').first().click()
        cy.get('[data-document-editor-target="previewBanner"]').should('be.visible')
      },
      // The comments heading and the empty-history line stay hidden behind the history
      // panel and its two versions; hidden, they still carry the colour they show in.
      targets: [
        ['save status', '[data-document-editor-target="saveStatus"]', 1],
        ['contents heading', '[data-document-editor-target="tocPanel"] h3', 1],
        ['read-only note', '[data-document-editor-target="previewBanner"] .text-sm > span:last-child', 1],
        ['panel heading', '.document-editor-panel h3', 2],
        ['empty-history line', '[data-document-editor-target="versionsEmpty"]', 1],
        ['version time', '[data-version-field="time"]', 2],
        ['author initial', '[data-version-field="avatar"]', 2],
        ['author', '[data-version-field="author"]', 2],
        ['version summary', '[data-version-field="summary"]', 2]
      ]
    },
    {
      ...COMMENTED,
      opened: 'the comments panel open on a thread',
      targets: [['comment excerpt', '.document-editor-panel .bn-header-text', 1]]
    },
    // BlockNote writes the placeholder on the empty block's `::after` once the editor has the focus.
    {
      page: 'block_editor/default',
      opened: 'the empty editor focused',
      open: () => cy.get('.bn-editor').first().click(),
      targets: [['placeholder', '.bn-block-content[data-is-empty-and-focused]', 1, '::after']]
    },
    {
      page: 'form/slim_select/optgroups',
      opened: 'the list open',
      open: () => cy.get('.ss-main').first().click(),
      targets: [['group label', '.ss-optgroup-label-text', 3]]
    },
    {
      page: 'form/slim_select/default',
      opened: 'a search that matches nothing',
      open: () => {
        cy.get('.ss-main').first().click()
        cy.focused().type('zzqx')
      },
      targets: [['no-results line', '.ss-list > .ss-search', 1]]
    },
    // The remote search is answered long after the guard has measured, so "Searching..." stays up.
    {
      page: 'form/slim_select/remote',
      opened: 'a remote search waiting on its answer',
      stub: () => cy.intercept('GET', /\/users\.json/, { delay: 30000, body: [] }),
      open: () => {
        cy.get('.ss-main').first().click()
        cy.focused().type('ana')
      },
      targets: [['searching line', '.ss-list > .ss-searching', 1]]
    },
    {
      page: 'filters/with_persistence?persist_enabled=true',
      opened: 'the panel open',
      open: () => cy.get('[data-filters-target="dropdown"] > button').click(),
      targets: [['auto-saved note', 'span.text-xs:has(> .icon-component)', 1]]
    },
    // `[busy]` is what Turbo sets while the frame loads; the placeholder is the component's own.
    {
      page: 'frame/default',
      opened: 'the frame busy',
      open: () => cy.get('turbo-frame#frame-preview-default').invoke('attr', 'busy', ''),
      targets: [['loading line', '.frame-loading > div', 1]]
    },
    // The multi-value control here is the one condition_controller.js writes, label and all.
    {
      page: 'data_table/complete',
      opened: 'a multi-value condition with nothing chosen',
      open: () => {
        cy.get('.filters button').contains('Filters').click()
        cy.get('[data-condition-target="attribute"]').select('genre')
        cy.get('[data-condition-target="operator"]').select('in')
      },
      targets: [['empty multi-value label', '[data-multi-select-target="label"]', 1]]
    },
    // A row is what direct-upload clones from this template once a file is picked.
    {
      page: 'direct_upload/basic_usage',
      opened: 'a file row in each uploader',
      open: () => {
        cy.get('[data-controller="direct-upload"]').each(($uploader) => {
          const row = $uploader.find('template[data-direct-upload-target="template"]')[0].content.cloneNode(true)
          row.querySelector('.file-name').textContent = 'minutes.pdf'
          row.querySelector('.file-size').textContent = '1.2 MB'
          $uploader.find('[data-direct-upload-target="fileList"]')[0].appendChild(row)
        })
      },
      targets: [
        ['file size', '[data-direct-upload-target="fileList"] .file-size', 2],
        ['percentage', '[data-direct-upload-target="fileList"] .percentage', 2]
      ]
    },
    {
      page: 'widget_grid/default',
      opened: 'the edit mode on',
      open: () => cy.get('[data-action="bali-widget-grid-edit-mode#enter"]').click(),
      targets: [['add tile', '.bali-widget-add-tile > span:last-child', 1]]
    },
    {
      page: 'topbar/user_menu',
      opened: 'a user menu open',
      open: () => cy.get('.bali-topbar-user-menu [data-dropdown-target="trigger"]').first().click(),
      targets: [['email', '.bali-topbar-user-menu:has([aria-expanded="true"]) .bali-topbar-user-menu-header > span + span', 1]]
    },
    // The section titles of the page's three menus: the ⋯ (a Dropdown title), the column
    // selector and the saved views. A click opens one at a time; `open()` is these two classes.
    {
      page: 'index_page/complete',
      opened: 'every menu open',
      open: () => cy.get('.dropdown:has(.menu-title)').invoke('removeClass', 'dropdown-close').invoke('addClass', 'dropdown-open'),
      targets: [['menu section title', '.menu-title', 4]]
    },
    // What the refresh controller does after two failed refreshes: the stamp stops being sr-only.
    {
      page: '/dashboard_widgets',
      opened: 'the freshness stamps showing',
      open: () => cy.get('.bali-widget-freshness').invoke('removeClass', 'sr-only'),
      targets: [['freshness stamp', '.bali-widget-freshness', 2]]
    }
  ]

  Object.entries(PREVIEWS).forEach(([page, targets]) => {
    THEMES.forEach((theme) => {
      it(`reads the muted text of ${page} at AA on the ${theme} theme`, () => {
        guard({ page, targets, theme, floor: AA })
      })
    })
  })

  OPENED.forEach(({ page, opened, stub, open, targets }) => {
    THEMES.forEach((theme) => {
      it(`reads the muted text of ${page} at AA with ${opened} on the ${theme} theme`, () => {
        guard({ page, stub, open, targets, theme, floor: AA })
      })
    })
  })

  // On a primary bubble the label stands on the theme's own pair, 5.25:1 on `afal`, where 70%
  // measured 3.33. daisyUI's `dark` paints that pair at 4.13 (theme-primary-contrast.cy.js).
  BALI_THEMES.forEach((theme) => {
    it(`reads the typing label on a primary bubble at AA on the ${theme} theme`, () => {
      guard({
        page: 'chat/typing_indicator?show_label=true',
        targets: [['typing label on a primary bubble', '#typing-end .chat-bubble-primary span.text-xs', 1]],
        theme,
        floor: AA
      })
    })
  })

  // A `primary` or `secondary` Footer is the theme's own pair, which daisyUI's themes leave under AA
  // in full: `secondary` 3.04:1 on `light` and `dark`, `primary` 4.13 on `dark`. Muted at daisyUI's
  // `.6`, the section title read 2.83:1 on `afal` over `primary` (#1281).
  const THEME_PAIRS = ['primary', 'secondary']
  THEME_PAIRS.forEach((color) => {
    BALI_THEMES.forEach((theme) => {
      it(`reads the text of a ${color} footer at AA on the ${theme} theme`, () => {
        guard({ page: `footer/default?color=${color}`, targets: FOOTER, theme, floor: AA })
      })
    })
  })

  it('keeps the compact timestamp no larger than the heading above it', () => {
    cy.visit('/bali/timeline/tracking')

    cy.get('.timeline-content-box > p.font-semibold + p').should(($stamps) => {
      expect($stamps, 'compact timestamps').to.have.length(3)
      $stamps.each((_, stamp) => {
        const size = el => parseFloat(el.ownerDocument.defaultView.getComputedStyle(el).fontSize)
        expect(size(stamp), `"${stamp.textContent.trim()}"`).to.be.at.most(size(stamp.previousElementSibling))
      })
    })
  })
})

// An icon that is the whole control or the whole answer is not text, but WCAG 1.4.11 wants
// 3:1 for it, and 1.4.3 wants as much for large text: the zero a Widget mutes is 30px. At
// `/50` a grey clears that over base-100 on every theme and not over the sidebar's base-200
// on `afal`, 2.96:1; `/55` is the first step on the scale that clears base-300 there too.
describe('muted icon contrast', () => {
  // page → [what, selector, how many the page renders]
  const PAGES = {
    'boolean_icon/all_states': [
      ['blank state', `.boolean-icon-component${GREY}`, 1]
    ],
    'side_menu/expandable_groups': [
      ['group chevron', '.arrow-icon', 2]
    ],
    'side_menu/with_menu_switcher': [
      ['switcher chevron', '.menu-switcher-chevron', 1]
    ],
    'filters/with_persistence': [
      ['bookmark', '[data-filter-persistence-target="iconDisabled"] > .icon-component', 1]
    ],
    'gantt/default': [
      ['expand toggle', '.bali-gantt button[aria-expanded]', 5]
    ],
    'widget/default?pattern=list&count=0': [
      ['zero figure', `.tabular-nums${GREY}`, 1]
    ]
  }

  const OPENED = [
    // The drop zone paints no surface of its own: straight on an AppLayout page it sits on
    // base-200, where `/50` measured 2.96:1 on `afal`. Over the preview's base-100 it was 3.05.
    {
      page: 'direct_upload/basic_usage',
      opened: 'the base-200 of a page under it',
      open: () => cy.get('[data-controller="direct-upload"]').parent().invoke('addClass', 'bg-base-200'),
      targets: [['drop zone icon', '[data-direct-upload-target="dropzone"] > .icon-component', 2]]
    },
    {
      page: 'data_table/with_search',
      opened: 'a query typed',
      open: () => cy.get('[data-filters-target="searchInput"]').type('abc'),
      targets: [['clear-search button', '[data-filters-target="searchClearButton"]', 1]]
    },
    // At `/50` this one measured 3.01:1 on `afal`, over its group's base-200/50: it never failed.
    {
      page: 'filters/with_applied_tags',
      opened: 'the panel open',
      open: () => cy.get('[data-filters-target="dropdown"] > button').click(),
      targets: [['remove-condition button', 'button[data-action="condition#remove"]', 2]]
    },
    // Mantine shows a comment's action pill on `mouseenter`. At `/50` its buttons measured
    // 3.05:1 on `afal`, over the pill's base-100: they never failed.
    {
      ...COMMENTED,
      opened: 'the comments panel open on a reacted comment, its action pill showing',
      open: () => {
        COMMENTED.open()
        cy.get('.document-editor-panel .bn-thread-comment').first().trigger('mouseenter')
      },
      targets: [
        ['add-reaction chip', '.document-editor-panel .bn-comment-add-reaction .mantine-Chip-label', 1],
        ['comment action', '.document-editor-panel .bn-action-toolbar :is(.mantine-ActionIcon-root, .mantine-Button-root)', 3]
      ]
    }
  ]

  Object.entries(PAGES).forEach(([page, targets]) => {
    THEMES.forEach((theme) => {
      it(`draws the muted icons of ${page} at 3:1 on the ${theme} theme`, () => {
        guard({ page, targets, theme, floor: NON_TEXT })
      })
    })
  })

  OPENED.forEach(({ page, opened, stub, open, targets }) => {
    THEMES.forEach((theme) => {
      it(`draws the muted icons of ${page} at 3:1 with ${opened} on the ${theme} theme`, () => {
        guard({ page, stub, open, targets, theme, floor: NON_TEXT })
      })
    })
  })
})

// The placeholder rule lives in two layers: unlayered in `bali/forms.css` for the input inside a
// `label.input`, which daisyUI paints from a sublayer of @layer utilities, and in @layer
// components in `bali/general.css` for an `input.input` or a `textarea.textarea`, which only the
// preflight paints. The contrast guard above sees neither promise the halves make: the unlayered
// half leaves a disabled control at daisyUI's `opacity: .2` (1.48:1 on `afal`, against 4.98 or
// more at 70%), and a host's `placeholder:` colour utility beats both halves without `!` — the
// unlayered one declares only the opacity, because a colour there would beat the host too.
describe('form placeholder cascade', () => {
  it("leaves the placeholder of a disabled input inside a label.input at daisyUI's opacity", () => {
    const search = '[data-filters-target="searchInput"]'
    cy.visit('/bali/data_table/with_search')
    cy.get(search).invoke('attr', 'disabled', '')
    cy.document().then(doc => doc.documentElement.setAttribute('data-theme', 'afal'))

    cy.get(search).should(($field) => {
      expect(transitions($field[0].ownerDocument), 'transitions settled').to.have.length(0)
      expect(paintedContrast($field[0], { pseudo: '::placeholder' }), `afal: disabled input inside a label.input "${$field.attr('placeholder')}"`)
        .to.be.below(2)
    })
  })

  // [page, what, selector]
  const FIELDS = [
    ['data_table/with_search', 'label.input input', '[data-filters-target="searchInput"]'],
    ['data_table/with_simple_filters', 'input.input', 'input.input[placeholder]:not(.hidden)'],
    ['form/text_area/default', 'textarea.textarea', 'textarea.textarea']
  ]

  FIELDS.forEach(([page, what, selector]) => {
    it(`yields the ${what} placeholder to a host utility`, () => {
      cy.visit(`/bali/${page}`)
      cy.document().then((doc) => {
        const host = doc.createElement('style')
        host.textContent = '@layer utilities { .host-placeholder::placeholder { color: rgb(255, 0, 0) } }'
        doc.head.appendChild(host)
      })
      cy.get(selector).first().invoke('addClass', 'host-placeholder').should(($field) => {
        const placeholder = $field[0].ownerDocument.defaultView.getComputedStyle($field[0], '::placeholder')
        expect(placeholder.color, `${what}: placeholder colour`).to.eq('rgb(255, 0, 0)')
      })
    })
  })
})

// The rule that lifts a `.table`'s thead and tfoot (bali/utilities.css) sits in @layer utilities
// after Tailwind's own utilities, so only its zero specificity lets a host's colour class on the
// thead win, and nothing in the contrast guard above would notice it stopped.
describe('table head cascade', () => {
  it('yields the thead of a hand-written table to a host colour utility', () => {
    const HOST = 'text-base-content/60'
    cy.visit('/bali/status/in_table')
    cy.get('table.table thead').then(($thead) => {
      const probe = $thead[0].ownerDocument.createElement('span')
      probe.className = HOST
      probe.id = 'host-colour-probe'
      $thead[0].ownerDocument.body.appendChild(probe)
      $thead.addClass(HOST)
    })
    cy.get('table.table thead th').first().should(($th) => {
      const doc = $th[0].ownerDocument
      const colour = el => doc.defaultView.getComputedStyle(el).color
      expect(colour($th[0]), `header with ${HOST} on its thead`).to.eq(colour(doc.getElementById('host-colour-probe')))
    })
  })
})

// The outline of a step still to come and the line into it, in the progress
// shape. Neither is text, but that shape's whole answer is the line, so WCAG
// 1.4.11 wants 3:1 against what they are drawn on (#1249). The line runs over
// the page or the card. The outline sits on its marker's `::before` disc, which
// stays base-100 inside a base-200 card that does not hand its surface over, so
// it is painted over the disc and measured against the disc and the card both:
// at `/50` it painted 2.77:1 there on `afal`, and the line 2.96 over the card.
describe('muted outline and line contrast in WorkflowSteps :progress', () => {
  const disc = el => el.ownerDocument.defaultView.getComputedStyle(el.parentElement, '::before').backgroundColor

  // [what, selector, how many the preview renders, how it is drawn]
  const TARGETS = [
    ['outline', '.workflow-step-circle[class*="border-base-content/"]', 10,
      el => ({ property: 'borderTopColor', under: disc(el) })],
    ['line', '.workflow-step-connector[class*="bg-base-content/"]', 7,
      el => ({ property: 'backgroundColor', over: el.parentElement })]
  ]

  THEMES.forEach((theme) => {
    it(`draws the grey outline and line at 3:1 on the ${theme} theme`, () => {
      cy.visit('/bali/workflow_steps/progress')
      cy.document().then(doc => doc.documentElement.setAttribute('data-theme', theme))

      cy.get('.workflow-steps-progress-rail').should(($shapes) => {
        expect($shapes[0].ownerDocument.getAnimations(), 'transitions settled').to.have.length(0)

        TARGETS.forEach(([what, selector, count, drawn]) => {
          const elements = $shapes.find(selector).toArray()
          expect(elements, `every grey ${what}`).to.have.length(count)
          elements.forEach((el) => {
            const step = el.closest('.workflow-step').querySelector('.workflow-step-title').textContent.trim()
            const ground = el.closest('.card') ? 'card' : 'page'
            expect(paintedContrast(el, drawn(el)), `${theme}: ${what} of "${step}" on the ${ground}`).to.be.at.least(NON_TEXT)
          })
        })
      })
    })
  })
})
