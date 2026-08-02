# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

> La línea **v3.0** vive en la rama `3.0`. Lo de abajo sale en `v3.0.0.beta.N`; las
> versiones `v2.x` de más abajo son la línea estable de `main`. Ver
> [Release channels](docs/guides/release-channels.md).

### Fixed

- **A date field or a select inside a modal `<dialog>` stops being decorative.** Widgets that portal their popup to `<body>` — flatpickr's calendar, SlimSelect's list, tippy's balloon, `ImageGrid`'s lightbox — were unusable inside any `<dialog>` opened with `showModal()`, in the package or in a host's own markup. The top layer paints above the whole document and above every `z-index`, so the popup was covered; and a modal dialog makes every node outside its own subtree **inert**, so it also stopped taking pointer events. A drawer or modal carrying a `date_field_group` — the ordinary case — had a datepicker the user could see and could not touch.

  **The measurement, because it is what picked the fix.** On `bali/drawer/dirty_form`, hit-testing the centre of a `.flatpickr-day` with `document.elementFromPoint` while a sibling `<dialog>` was open: calendar under `<body>` with no dialog gives `SPAN.flatpickr-day`; with the dialog open it gives `DIALOG.modal`. Calling `showPopover()` on the calendar while it stayed under `<body>` did **not** fix it — `elementsFromPoint` returned `[DIALOG, HTML]`, the calendar absent from the hit-test stack entirely, because the top layer does not lift a node out of the dialog's inertness. Moving the calendar into the `<dialog>` fixed the hit-test at scroll offset 0 but put the calendar 900px off-screen once the page behind was scrolled, since `showModal()` does not lock that scroll. Only both together work: moved in **and** `showPopover()` gives `SPAN.flatpickr-day` at any offset, and a real mouse click on day 14 with the page at scroll 900 selected `2026-08-14`.

  So the two halves are load-bearing for different reasons, and neither is optional. Moving the node into the overlay's subtree is what defeats the inertness. `showPopover()` is what restores the coordinate system: both widgets position their popup in document coordinates (`window.scrollY + rect.top`), which is right for a child of `<body>` and wrong for a child of a `position: fixed` dialog — as a top-layer element it resolves `position: absolute` against the initial containing block again, so the numbers the widget already wrote become correct without patching either library's arithmetic. It also lifts the popup clear of the panel's `overflow-y: auto`.

  **`assets/javascripts/bali/utils/top-layer.js`** is the shared implementation — `topLayerHost`, `enterTopLayer`, `leaveTopLayer` — and it is **published**, not internal: `import { topLayerHost, enterTopLayer, leaveTopLayer } from 'bali-view-components/utils'` works, because the module is re-exported from `app/frontend/bali/utils/index.js`, which the `exports` map already publishes as `./utils`. A host that portals an overlay of its own hits exactly the same wall, and neither half of the fix is guessable, so it gets the move instead of having to rediscover it. Each controller takes only what it needs: flatpickr joins on `onOpen` and leaves on `onClose`; `.ss-content` joins once at connect, because SlimSelect debounces all four of its open/close callbacks by 100 ms and a hook there would fire long after the list was on screen; tippy is only *moved*, no popover, because Popper recomputes its offsets against the new `offsetParent` and the dialog root is `position: fixed`; `ImageGrid`'s lightbox is `position: fixed; inset: 0`, so it has no offsets to keep correct. Two small CSS blocks undo the `[popover]` rules from the UA stylesheet that `bali/datepicker.css` and `bali/slim_select.css` did not already override — `inset: 0`, `margin: auto`, and for the calendar `overflow: auto`, which would have turned it into a scroll container clipping its own arrow.

  **Nothing changes outside a modal dialog**, and that is deliberate: `topLayerHost` keys off `:modal`, so a `<dialog>` opened with `show()` — an ordinary positioned box the stacking scale already orders — and every page that has no dialog at all leave the widgets untouched. Verified on the same previews: with no dialog the calendar still lives under `BODY`, carries no `popover` attribute, and its days still hit-test as themselves. The datepicker is also left alone when the call site put the calendar in flow (`static`) or named its own container with an `appendTo` target, since both are a decision the widget should not override.

  **The stacking scale now says what it cannot do.** `--bali-z-command: 500` through `--bali-z-tooltip: 800` order overlays *within the document*; against anything in the top layer no number wins, and the rule that follows is that an overlay needing to cover a top-layer element has to join the top layer too. That is written into the header of `bali/z_index.css` and into a new guide, `docs/guides/overlays-and-the-top-layer.md`. **Deliberately not wired:** the BlockNote portals inside `BlockEditor` and `Status`' panel, which read `--bali-z-popover` but are not reachable from inside a modal dialog today — wiring them without a case to measure against would be guessing. `Modal` and `Drawer` themselves do not use `showModal()` yet; that is the next cut of #679, and this change is its precondition.
- **`Bali::Filters` stops throwing the chosen value away when the operator changes, and stops submitting conditions it knows the server will discard.** Reported from production against a real listing: *"the year filter doesn't filter"*. Pick an attribute, pick a value, switch the operator from "is" to "is not" — and the value is gone. The condition then travelled as `q[g][0][initiative_year_not_eq]=`, a Ransack predicate with a blank value, which Ransack drops without raising. The page answered 200, the table painted, and the only thing wrong was that the result was not the one that had been asked for. Reproduced here on `/admin/movies` before the change: the request that came back with all 20 rows was `GET /admin/movies?q[g][0][m]=or&q[g][0][genre_not_eq]=`, while the URL pushed into the address bar said only `?q[g][0][m]=or` — the bar and the response described different queries, and neither said anything was wrong.

  **The value survives an operator change that keeps the same widget.** `operatorChanged` rebuilt the value input for *every* operator on a `select`, `date` or `datetime` attribute. But "is" → "is not" renders the same widget over the same option list, and so do "is" → "after" → "on or before" on a date: the rebuild changed nothing except the `name` attribute, which `updateFieldName` was already handling on its own. The rebuild now happens only when the operator actually asks for a different widget — single versus multiple for a select, single versus range for a date — and the answer comes from the rendered DOM rather than from the previous operator, so a server-rendered row and a JavaScript-rendered one are read the same way. As a side effect the SlimSelect instance is no longer destroyed and rebuilt on every operator change.

  **A widget swap carries over what maps one-to-one, and drops the rest out loud.** Going from "is" to "is any of" on the same attribute keeps the chosen option as the one checked box, and coming back the other way with a single box checked keeps it as the chosen option. Several checked boxes collapsing into a single select would silently keep one and lose the others, so all of them are dropped instead and the row says so. A point date moving to `between` is dropped for the same reason and with the same note: an instant and an interval are different kinds of value, and half a range is a different filter rather than a narrower one — `between` needs both ends or it does not travel at all.

  **Nothing blank is submitted any more.** On Apply, the value inputs of a condition that has no attribute (they carry the internal `__ATTR__` placeholder in their name) or an attribute with no value are disabled for the length of the submission, which keeps them out of the request *and* out of the URL that is pushed alongside it. The group combinator `q[g][0][m]` deliberately stays: it is not a predicate, and it is what tells the server that a filter set was submitted and happens to be empty. Dropping it too would make an emptied panel indistinguishable from a request that carried no filter state at all, which a host with filter persistence enabled answers by restoring the previous filters — so the existing "empty the panel, press Apply, the filters clear" behaviour is preserved exactly.

  **The silence is over.** A condition that has an attribute and no value now carries a warning-coloured note under its value input reading "No value chosen, so this condition is ignored" (`bali_view.filters.incomplete_condition`, in `en` and `es`), announced through `role="status"`. It appears the moment a row that had a value loses one — cleared by the user, or dropped by a widget swap that could not carry it — and on Apply for every row that had to be left out. It does not appear while a row is merely being filled in for the first time, and choosing a different attribute clears it. A row that *arrives* incomplete is flagged on connect, which is what a URL bookmarked before this fix looks like.

  **What a host that updates will notice.** A condition with no value is no longer echoed back after Apply: a panel with one filled row and one half-filled row comes back with the filled row only, because the half-filled one never reached the server. That is the fix rather than a side effect — a row that round-trips forever while filtering nothing is what produced the original report — but it is visible. The note's markup is new (`.filters-condition-hint`, styled in `app/components/bali/filters/index.css` as a real rule rather than a utility, because JavaScript decides when it shows and Tailwind does not scan this package's JavaScript), and the value input is now wrapped in one extra `div` so the note can sit beside the container the controller rebuilds. Nothing is renamed and no public API moves.

  **Deliberately not done.** `FiltersController#buildUrl` reads `this.searchFormTarget` unconditionally, so Apply raises and does nothing at all in a `Filters` rendered without `search:` — which is every Lookbook preview of the component. It predates this change, it has a different root cause, and it is filed separately rather than folded in here.
- **`Bali::Filters` rendered without `search:` has a working Apply button again.** Clicking it did nothing at all — no request, no navigation, no message — and the only trace was the exception Stimulus swallows. `buildUrl()` read the quick-search form through `this.searchFormTarget`, and that form is painted only when the host passed `search:`; Stimulus' target getter throws `Missing target element "searchForm"` when it is absent, and `_submit()` builds the URL *before* calling `form.requestSubmit()`, so the throw took the whole submission with it. The form is read through `hasSearchFormTarget` now, exactly as `preservedParamsUrl()` a few lines above already did.

  **Who was hitting it.** Any host rendering `Bali::Filters` directly without a quick search — which the inline panel (`popover: false`) always is, since it has no search box by design. A `DataTable` with `with_filters_panel` was never affected, because the panel it composes always brings one; that is how a bug this total survived a library whose canonical listing looks like it works. None of the component's own Lookbook previews configures a search, so all of them were in the broken configuration. It predates #652 and its fix (#798) and shares no cause with either — #798's entry above filed it here rather than folding it in.

  **The URL that gets pushed no longer repeats itself.** While `buildUrl` was open: it appended the forms' params onto a URL that can already carry them, because `urlValue` is the listing's own URL and the params that have to survive a filter (`locale`, `group_by`, `view`, any `preserved_params`) are painted as hidden fields *and* live in that URL. Measured on `/admin/movies?locale=es`, applying a filter pushed `?locale=es&locale=es&…`. Nothing broke — the server keeps one — but that is the URL the user copies out of the address bar. Each key now drops whatever the base URL held for it the first time the forms write it and appends after that, so a multi-value field still contributes all of its values.

  **Covered by `cypress/e2e/filters-controller.cy.js`**, which is where a Stimulus regression can be caught at all: the two configurations (a `Filters` without `search:`, popover and inline; a `DataTable` panel with one) and the pushed URL. Against the code before this change three of its five tests fail; the two that guard #798's behaviour pass on both sides, which is what makes them guards.

  **Deliberately not done.** `submitSearch()` reads the same target unguarded and is left alone: its only call site is `data-action` on the quick-search form's own submit button, so the path cannot run without the markup that defines the target. The rest of the package was swept for the same shape — an unguarded single-target read on a path that can run without the markup — and what turned up is not in `Filters`, so it is filed on its own rather than widened into this fix.

- **The overlay stops taking the focus away from the field the host asked to focus, and stops going deaf while it loads.** Four defects in `Modal` and `Drawer`, all of them present on every open, none of them caught by a test.

  **`autofocus` never won in a modal.** `openModal` called `autoFocusInput(contentTarget)` and *then* `trapFocus()`, and `trapFocus` ended on `firstFocusable.focus()` — so the last write won and the host's `autofocus` was overwritten every time. In the shared `#main-modal` the outcome was deterministic rather than merely racy: `AppLayout` passes no `header` slot, which makes the component render the standalone `✕`, and that button precedes the content target inside the panel. Measured on `/movies/1` before the change, opening the "Add character" modal whose form carries `autofocus: true`: the accessible element holding the focus was `BUTTON[aria-label="Close modal"]`, with `INPUT#character_name` sitting unfocused beside it. Focus now resolves in the order the host would expect — `[autofocus]` inside the content, else the first focusable, else the panel — and `autoFocusInput` is gone from this path rather than being resequenced, because two functions competing to decide one thing is what produced the bug.

  **Escape and Tab did nothing for the whole length of the fetch.** `open()` shows the panel with `content: null` so the skeleton paints immediately, and the old `openModal` only entered its focus branch when content was non-null. So during the entire fetch the focus stayed on the trigger link, which lives in a sibling subtree of the panel: a keydown born there bubbles `a → .app-layout-body-container → main` and never crosses the panel that holds the `keydown.esc->modal#close` action. Measured on `/movies/1` before the change: at skeleton time the active element was `BODY.app-layout`, outside the panel, and an Escape dispatched from it left the modal open. There was no Tab trap either, because the trap's listener was installed inside the same skipped branch — and it stayed missing even after loading if the loaded content happened to contain nothing focusable, since `trapFocus` returned early on an empty node list. Both panels now carry `tabindex="-1"` so focus can rest on the panel itself when there is nothing else, the trap is installed on every open rather than only on a content-bearing one, and Tab with nowhere to go is held rather than let out to the page behind the overlay.

  Making Escape work during the skeleton created a second case that could not happen before, and it is fixed with it: **an overlay abandoned mid-load no longer pops back open.** Once Escape can close a panel while its fetch is still in flight, the arriving content reopens it — measured against a deliberately delayed response, the panel closed on Escape and came back 2.5 seconds later with the form in it. Every close now stamps a sequence number that `open()` re-checks after its `await`, so a response nobody is waiting for is dropped. A close followed by a fresh open bumps the stamp twice, which invalidates the abandoned one too and lets the newer open own the panel.

  **A failed submit disarmed the unsaved-changes guard.** The error branch of `submit` re-rendered through `openModal`, whose first statement is `this._dirty = false`. So a 422 — the one response that means the user's input is still unsaved and still on screen — left the drawer marked clean, and the next Escape discarded a filled-in form without asking. The branch now goes through a `_replaceContent` that swaps the panel's content and re-seats the focus without touching the dirty flag or the element focus will be restored to, neither of which the failed submit changed.

  **`aria-labelledby` named an element that was not there.** `Modal` emitted it unconditionally, but `title_id` only reaches the DOM through the header slot — so every modal built from `content` and every `#main-modal` pointed the dialog's accessible name at a missing node, which is worse than no name at all because it suppresses the fallback. It is now conditional on the header slot, matching what `Drawer` already did. The test that covered this asserted the broken behaviour (it rendered a modal with no header and demanded the attribute), so it was replaced by a pair that pins both directions.

  **`Drawer` now inherits its behaviour instead of copying it.** `DrawerController` carried its own near-identical `openModal`, `_closeModal`, `_applySize` and `open` — which is the mechanical reason every bug above existed twice and had to be fixed twice. The differences turned out to be four names (the open class, the size map, the trigger's size attribute and its key), so those are hooks now and the drawer file drops from 158 lines to 71. Opening, closing, the focus trap, the confirm-on-close guards including the flatpickr one, and `submit` are single implementations. **This is behaviour-preserving and no public API moves**: the event names, the `data-drawer-*` attributes, the size maps and `_restoreDefaultSize`'s drawer-specific restoration of the default width are all unchanged.

- **A tooltip is reachable with the keyboard, which it never was.** `Bali::Tooltip` shipped `trigger_event: "mouseenter focus"` from its first version, and the `focus` half of that string could not fire in any tooltip the library has ever rendered. tippy honours `focus` only when the focused element **is** the reference it was given, and the reference is the `<span class="trigger">` the template wraps the slot in — no `tabindex`, so it never takes focus. A focus landing on the caller's own button or link inside the slot is a `focus` event that does not bubble, so it never reached the reference either. Measured in Chrome on `bali/tooltip/default` with a focusable control in the slot: `state.isVisible` **false** on real focus with `focus`, **true** with `focusin`, which bubbles, and the balloon's text present in the DOM. The default is `"mouseenter focusin"` now, exactly as #774 already respelled `Bali::HoverCard`'s; a test pins the two to the same string so they cannot drift apart again. Anyone passing `trigger_event:` explicitly still wins, and nothing regresses, because the branch being replaced was dead: `mouseenter` was the only trigger that ever fired.

  **That fixes half of it.** `focusin` only helps a slot that has something focusable in it, and the most common tooltip in the library does not: the `?` help tip is a bare `<span>`. Measured on `bali/tooltip/help_tip`, Chromium's accessibility tree reported **no interactive element on the page at all** — the balloon existed only for a mouse, which is WCAG 1.4.13 with nothing on the other side. The controller now gives the wrapper `tabindex="0"` **only when the slot brought nothing focusable of its own**, so the help tip becomes a tab stop and a trigger built out of a `Button` or a `Link` keeps its single stop instead of gaining a second, unnamed one in front of it. `disconnect` takes the attribute back off, and an empty tooltip — one whose content is blank, which builds no tippy instance — never gets it, so it does not claim a tab stop for a balloon that will not open. **What a host that updates will notice:** help-tip-shaped tooltips add one stop each to the tab order of the pages they are on. That is the fix, not a side effect, but it is visible. Inside the package the only render that changes is `FieldGroupWrapper`'s `tooltip:` icon — an `info-circle` SVG with nothing focusable in it, so every form field carrying a `tooltip:` gains a stop next to its label. The two `SideMenu` tooltips do not: one wraps an `<a href>` and the other a `div[tabindex="0"][role="button"]`, and both keep the single stop they already had.

  A new `bali/tooltip/keyboard_reach` preview puts the two slot shapes side by side, and `cypress/e2e/tooltip-controller.cy.js` walks both with real focus, asserting the balloon opens, closes on `focusout`, carries the `aria-describedby` tippy wires up, and that the wrapper stays out of the tab order in the case where the caller supplied the control. Deliberately **not** done: moving `aria-describedby` off the wrapper and onto the caller's control. tippy puts it on the element it was handed, so a screen reader reading a focused `<button>` inside the slot is not read the description — that is a real gap, it needs the reference to become the control itself rather than the wrapper, and it changes the slot contract rather than a default.

- **A tooltip whose balloon holds markup but no plain text is built now; before, it silently did not exist.** `TooltipController#connect` opened with `if (this.contentTarget.content.textContent.trim().length === 0) return`. The intent was sound — do not build a balloon for a tooltip with nothing to say — but the question it asked was "is there any text?", and the component is explicitly designed to carry HTML: the template puts the content inside a `<template>` and tippy runs with `allowHTML: true`. So balloon content that is only an `<img>`, only an `<svg>`, only a chart — an image preview, an icon legend, a sparkline, every one of them a legitimate use of the markup channel the component provides — has `textContent === ''` and returned right there. Measured on the markup the template emits, with the newlines the ERB leaves around the content: `<p>Plain help text</p>` gives `textContent.trim()` **15** and `children` **1**; an `<svg>` on its own gives **0** and **1**; no content at all gives **0** and **0**. The check is now "no text **and** no elements", which is the difference between "nothing to say" and "nothing written in words". `childNodes` cannot draw that line — an empty tooltip's `<template>` still holds the whitespace text node the ERB leaves behind, so it counts 1 either way — and `innerHTML.trim()` would read an HTML comment as content, so neither was used.

  **The genuinely empty tooltip is deliberately unchanged.** `with_trigger` with no content block still builds no tippy instance and still takes no `tabindex`, so #776's reasoning survives intact: a balloon that will never open must not claim a stop in the tab order. Building an empty balloon instead would have traded a silent failure for a visible one — an empty box appearing on hover — and no call site wants that.

  **What a host that updates will notice, and it is two things rather than one.** Every tooltip in the host's app whose balloon carries no plain text goes from not existing at all to existing: the balloon opens on hover now, and — because `makeTriggerFocusable()` runs *after* this guard and therefore never ran for these — the wrapper also picks up `tabindex="0"` and adds one stop to the tab order of its page, exactly as #776 described for the help-tip shape. Both are the fix rather than side effects, but a page can gain several stops at once. **Nothing inside the package or the dummy changes.** Sweeping the raw HTML of all 486 Lookbook previews plus the dummy's own pages found 182 `Tooltip` renders across 27 pages: 179 already carried text and are untouched, 1 is the `empty_tooltip` preview and stays skipped, and the only 2 that change status are the two in the new `bali/tooltip/markup_content` preview this change adds. `FieldGroupWrapper`'s `tooltip:` and both `SideMenu` flyouts pass a String or a name as their content, so they were already on the built side.

  That new preview holds an image balloon and an `<svg>` balloon, and `cypress/e2e/tooltip-controller.cy.js` — the spec #776 left behind — grows three cases rather than a second file: the balloon opens around the image, it opens around the `<svg>`, and the page's tab order gains exactly one stop per tooltip and nothing else. All three fail against the old guard, and they fail on the shape of the bug rather than incidentally: `cy.focus()` rejects the wrapper because it is not a focusable element. The existing empty-tooltip case passes on both sides, which is what pins that this change left it alone.

  Deliberately **not** in this change. `HoverCard` reaches its template through `templateTarget.innerHTML` and has no emptiness guard at all, so it does not share this defect; it does build a tippy instance with an empty string when there is neither template nor URL, which is a different question and is filed on its own. Nor does this touch the fact that tippy *moves* the `<template>`'s nodes into the balloon rather than cloning them, leaving the template empty — so a controller that disconnects and reconnects on the same DOM node builds nothing the second time. Measured, real, older than this bug, and filed separately rather than folded in here.

- **The editors' JavaScript stops writing English into a Spanish app.** #695 put every Ruby and ERB string of `DocumentEditor` and `BlockEditor` through I18n — the `component.html.erb` of `DocumentEditor` did not call `t()` once, and seventeen strings went in. What it could not reach is the text the *client* generates, and that is the text the user spends the most time looking at: the save-status line changes on every keystroke and every auto-save, and it read "Unsaved changes", "Saving...", "Saved at 3:41:07 PM" and "Save failed" no matter what locale the app was running in. Eighteen strings across five modules are now served by Rails.

  **The channel is chosen per string, and that is the whole design.** Nothing here interpolates i18n in JavaScript that Rails could have interpolated itself. The four save states and the version-preview label are Stimulus `String` values on the `document-editor` element, because the controller writes them after a `fetch` resolves and there is no element to pre-render. The two version-list states — `Failed to load versions.` and `No versions yet.` — are instead rendered up front, hidden, and merely revealed: they carry no runtime data, so this is the `BulkActions` pattern rather than a value, and the controller now toggles a `hidden` class instead of building a `<p>` and setting its `textContent`. Everything the React bundle renders travels as ONE JSON value (`data-block-editor-translations-value`), the channel `filters/condition/component.rb#translations_json` already established, because those strings are spread across four modules that all hang off the same controller. Three strings *do* keep a placeholder — `%{time}`, `%{number}`, `%{size}`/`%{max}`, `%{status}`, `%{id}` — and are substituted in JavaScript with `String#replaceAll`, the way `kanban/index.js` already does it, for the one reason that justifies it: only the browser knows a clock time, a file size or an HTTP status.

  **`_timeAgo` was deleted rather than translated.** It reimplemented relative time as four hardcoded English strings (`just now`, `${n}m ago`, `${n}h ago`, `${n}d ago`). `Intl.RelativeTimeFormat` produces the same four buckets in the app's own locale, so the fix removes the strings instead of adding keys for them; the locale reaches it through a `document-editor-locale-value`, emitted exactly as `timeago/component.rb` already emits one. `style: 'narrow'` keeps the output as short as the wording it replaces, because the slot it fills is 11px and tabular — measured in Spanish: `ahora`, `hace 20 h`. `toLocaleTimeString` in the saved-at status gets the same locale, which is why it now reads `20:11:08` rather than `8:11:08 PM` under `es`.

  **Restoring a version stops using `window.confirm`.** It goes through `confirmDialog`, the styled `<dialog>` the rest of the package already uses, and reads its title, accept and cancel labels off `data-bali-confirm-*` attributes the server renders translated — the same channel `DeleteLink` uses. Beyond the wording, this is the difference between a dialog automated browser tooling can operate and one it cannot.

  **Where the strings are.** `bali_view.document_editor.{status_unsaved,status_saving,status_saved,status_failed,version_label,versions_error,versions_empty,restore_confirm,confirm_title,confirm_accept,confirm_cancel}` and `bali_view.block_editor.{load_failed,table_of_contents,upload_not_configured,upload_too_large,upload_failed,user_fallback,plain_text}`, in `en` and `es`, with no inline `default:`. Nothing is renamed or removed, so **this breaks nothing for a host that updates** — an app that has overridden Bali's locale file simply gains eighteen keys it has not translated, which fall back to English exactly as they behave today. The one implementation detail worth knowing: `BlockEditor` gathers its strings in `before_render` rather than in `initialize`, because ViewComponent raises `TranslateCalledBeforeRenderError` for a `translate` call made before the view context exists — the nested editor inside `DocumentEditor` hits this on every render.

  **What this deliberately does NOT do.** `RichTextEditor`'s slash-menu and node-selector labels stay in English: the component is deprecated for removal in 4.0, and the answer for those is the migration to `BlockEditor`, not a set of keys that gets deleted with it. `useFileUpload`'s two `throw`-only messages (`CSRF token meta tag not found…`, `Invalid URL returned…`) also stay in English — they never reach the DOM and they are aimed at whoever is wiring up the endpoint. And `inlineContent.jsx`'s `DEFAULT_ENTITY_TYPE_CONFIG` labels (`Task`, `Project`, `Document`) are untouched: those already have a host-facing channel in `references_config:`, so translating them means moving the default out of JavaScript and into Ruby, which changes a public default rather than adding a key, and belongs with whoever owns that API.
- **A toast that never left.** Removing a `Notification` was gated on an `animationend` event, and that event does not always arrive. The controller added a class and waited: no animation, no event, no removal, and the toast sat on screen for the rest of the session. The class it added, `fadeOutRight`, had **no CSS behind it at all** until March 2026, when the keyframes landed as a side effect of an unrelated mobile-responsiveness PR (#505) — so for the whole life of v1 and most of v2 a Bali notification simply never went away. That is the reason `centinela`, `afal-apps` and `costa-norte` each carry their own byte-for-byte reimplementation of the auto-dismiss.

  The keyframes existing does not close the hole, because `animationend` still fails to fire in cases a host hits: Chrome freezes CSS animations in a background tab (measured on the v2 controller in this repo — `playState: "running"`, `currentTime: 0`, element still in the DOM seventeen seconds after a three-second delay), and any host that points the controller at a leaving class of its own that it never styled is back to the original bug. `AlertController` reads the leaving animation's length back out of `getComputedStyle` and removes the element on a timer instead. No animation means a computed duration of `0s` means the element goes at once, which is also, for free, what `prefers-reduced-motion` now gets: the stylesheet zeroes the animation and the JavaScript needs no branch. Measured after the change, in a **hidden** tab, on a container of four toasts with `duration: 1500`: entering at t=0, leaving at t≈2.5s, out of the DOM at t≈4.5s.

  Two related behaviours went with it. `disconnect()` used to remove the element, so a toast inside a Turbo Frame deleted itself whenever the frame re-rendered; it now only clears its timers, and the element is kept out of Turbo's page cache by `data-turbo-temporary` rather than the older `data-turbo-cache="false"`. And `Bali::AppLayout` used to wrap the flash in its own `aria-live` region containing alerts that were live regions themselves — a live region inside a live region is not reliably announced by anything. The container is plain furniture now; the roles are on the toasts.

- **`Bali::AppLayout` stops dropping most of the flash.** It read `flash[:notice]` and `flash[:alert]` and rendered nothing for anything else, so `flash[:warning]` and `flash[:info]` disappeared silently. It hands the whole hash to `Bali::ToastContainer` now, which maps `notice`/`success`, `alert`/`error`/`danger`, `warning` and `info`, and ignores keys that are state rather than messages (`flash[:timedout]` and friends).

- **The Costa Norte theme sampler shows its four alerts again.** The preview passed its block to `Component.new` instead of to `render`, so `new` ignored it and all four rendered as bars of colour with no text at all.

- **Two dummy call sites that were quietly rendering the wrong thing.** `documents/_form` passed `variant: :error` to a component with no `variant:` keyword, so a list of form validation errors rendered as a green success notification; it is a `Bali::Alert(color: :error)` now. `characters/create.turbo_stream` and its destroy counterpart passed `color:` and `dismissible:` to `Notification`, which had neither, and got a fixed-position notification where the template clearly wanted an inline one.
- **Five more dummy tooltips that drew nothing at all — no icon, no balloon, and one blank table column.** `admin/analytics` (3 call sites) and `admin/revenue` (2) called `Bali::Tooltip::Component` with `text:` and `position:`, neither of which the component declares — it takes `placement:`, `trigger_event:` and `append_to:` — so both landed in `**options` and came out as literal `text="Movies sorted by rating, highest first" position="right"` attributes on the wrapper, while `data-tooltip-placement-value` stayed at its `top` default and the `right`/`left` the caller asked for never applied anywhere. Each block was also passed without capturing the slot (`do` rather than `do |tooltip|` + `with_trigger`), so what the caller meant as the trigger went to `content`, which the template puts inside a `<template>` — and a `<template>` renders nothing. Nine renders on the two pages had **no visible trigger at all**. The Top Rated Movies table was worse than the issue reported: there the thing routed into the `<template>` was `movie.name`, so the entire Movie column rendered blank for all five rows. The balloon did not exist either, for the four icon-only renders: `TooltipController#connect` returns early when the template's content has no text, and an `info` SVG has none, so tippy was never constructed and the help text lived only in an attribute nobody reads. The other five — the table rows — did build a tippy, since a movie name is text, but it hung off a trigger with nothing in it to hover. All five now pass `placement:`, put the icon or the movie name in `with_trigger`, and put the help text in the content block; with the keyboard fix above already in, the wrapper picks up `tabindex="0"` and all nine open on focus as well as on hover. **This changes nothing in the package, so a host that updates sees no difference** — but the dummy is what gets copied, and five examples were teaching an API that does not exist.

  A sweep of the rest of the dummy for the same shape — a `render Bali::X::Component.new` passing keywords the component does not declare, checked by reflection against `initialize` across the whole ancestor chain — is deliberately **not** in this change. It found four more clusters, none of them Tooltip, and they are filed separately rather than smuggled in here.

- **The dummy stops declaring a route it cannot serve.** `resources :documents` announced all seven RESTful routes, but `DocumentsController` implements six — there is no `edit` action and no `edit.html.erb` — so `GET /documents/:id/edit` answered 404 `AbstractController::ActionNotFound` to anyone who followed it. It is a dead route rather than a missing action: editing a document in the dummy does not happen on a page of its own, it happens in the overlay `documents/show.html.erb` opens, so nothing links to `edit_document_path` anywhere in the app. The route is now `resources :documents, except: :edit`, which is what the controller has always meant, and the 404 that remains is an honest `ActionController::RoutingError` for a URL the app never advertised. Found by the dummy-pages smoke test (#789) on its first run. **This is dummy-only and changes nothing in the package**, but the dummy is the reference hosts copy from, and a resource block that over-declares its actions is the kind of thing that gets copied along with everything else.

- **Pagination links stop throwing the reader out of the page they are on.** Every paginating Lookbook preview emitted `href="/lookbook?page=2"`, so clicking page 2 in `data_table/with_pagination` left the component and landed on Lookbook's home. Measured before the fix across the paginating previews — `data_table/with_pagination`, `/complete`, `/with_bulk_actions`, `/with_grouping`, `/with_simple_filters`, `index_page/complete`, `pagination_footer/default` — all of them; after, all of them stay put, walked with real clicks through the first, a middle and the last page in both the raw preview and the inspector's iframe.

  The cause was **not** the component. `ApplicationViewComponentPreview#request` — the plain Hash Pagy accepts in non-Rack contexts — hardcoded `path: "/lookbook"`, and Pagy dutifully built every link against it. A preview has no single URL: the same render is served at `/lookbook/preview/<path>/<scenario>` and inside the inspector's iframe, and the preview object never sees the request in either case. The stub now says `path: nil`, which is Pagy's own way of spelling "relative to wherever this is": the links come out as `?page=2` and the browser resolves them against whichever of the two the reader is actually on. The stub still carries `params: {}`, so a preview's own params (`?view=grid`) do not survive a page click — unchanged, and not fixable centrally, since only the preview method knows them.

  The second half is host-facing. `Bali::DataTable::Component` forwarded **nothing** to the `PaginationFooter` it renders, so a host whose Pagy carries no request — built by hand rather than through the `pagy()` helper, which is a case `Bali::Pagination::Component` explicitly supports through `url:` — fell back to a bare `?page=2` and had no parameter anywhere on `DataTable` with which to fix it. It now forwards a base, **but only when the Pagy cannot build its own URLs** (`PagyAdapter#linkable?`). The naive version of this fix — forwarding `url:` unconditionally — was measured and rejected: a base wins over a linkable Pagy by design (#654), and `url:` is the *filtering* base, which hosts pass without a query string (`admin_movies_path`), so `/admin/movies?q[...]=n&page=1` became `/admin/movies?page=2` and a listing lost its applied filter on every page change. Verified by clicking through `/admin/movies?q[name_or_genre_or_studio_name_cont]=n`: 17 of 20 movies before, "Showing 11-17 of 17" after the click, with the search box still holding its term. Three tests pin all of it, and each of them fails against the naive version.

  What is forwarded is not the raw `url:` either: it is the same URL the view switch and "Group by" already build from it — `url:` merged with the current query string, minus the one-shot params (`page`, `clear_filters`, `clear_search`) — so a non-linkable Pagy now preserves filters, sorting and the applied saved view instead of merely pointing at the right path. Deliberately **not** done: a separate `pagination_url:` on `DataTable`. A second URL argument that only matters in one of the two Pagy shapes is a footgun, and the listing can derive the value.

- **The calendar no longer 500s on a query string.** `Bali::Calendar::Component#normalize_date` called `Date.parse` with no rescue, so `?start_date=zzz` was an unhandled `Date::Error` — a 500 any visitor can trigger with no session, no account and no knowledge of the app, on every page that hands the component a date from the URL. That is the documented way to use it: the header's prev/next links write `?start_time=…` back to `route_path`, so the host is expected to read that param and pass it through. The inconsistency was internal too — `normalize_period`, six lines below, already degraded to `:month` instead of raising.

  Measured against `/showcase` in the dummy app, which now reads the params its own header emits. Before: `?start_time=zzz` **500**, `?start_time[]=1` **500**, `?start_time=2026-13-45` **500**, `?start_time=` 200 (blank was the single case already handled). After: **200, 200, 200, 200**, all four rendering the current month.

  Two neighbours had the same shape and are fixed with it, because hardening one query parameter and not the one beside it is not a fix. `normalize_period` did `(period || :month).to_sym` and `Array` has no `#to_sym`, so `?period[]=1` was a `NoMethodError` — **500 before, 200 now**; it compares against `PERIODS` as strings now rather than interning visitor input. And `Calendar::Header::Component` parsed *its own* `start_date` without the `#to_s` the parent applied, which is the one place an Array reached `Date.parse` as a `TypeError` rather than an `ArgumentError` — precisely the case a rescue written for `ArgumentError` alone misses. Both rescues now live in one `Bali::Calendar::Normalization` included by the component and by its header, because drift between two copies of the same normalizer is what produced this in the first place.

  **What this deliberately does NOT do.** It does not validate. An out-of-range date and a typo are indistinguishable to the component and both quietly become today — no flash, no 404. A host that needs "that date does not exist" to be visible to the user has to check the param before handing it over; the component's job here is only to stay up. And no other component was audited for unrescued `Date.parse`.

- **`help:` now means the same thing in every field type.** The three select families — `select_group`, `slim_select_group` and `time_zone_select_group` — take a *second* positional hash, and each had decided on its own which of the two `field_helper` would see. All three chose the last one, so a `help:` written next to `label:` — where the caller naturally writes it, and where the sixteen single-hash field types read it — reached the wrapper and never reached the paragraph. It vanished with no error, no warning and no failing test: the field rendered, just without its hint. Measured before the fix on identical calls: sixteen field types rendered the hint, those three dropped it.

  The keys the *group* owns (`label:`, `help:`, the addons, `control_class:`, `control_data:`) are now gathered from every hash the helper takes, through one `HtmlUtils#group_options`. **The first hash wins on a conflict** — it is the caller's primary one, the one holding `label:` — and that precedence is now the same whether the wrapper or the paragraph is doing the reading, which it was not before.

  What does *not* change is the HTML attributes hash. `group_options` copies only the caption keys, so `slim_select`'s Stimulus target, its `select_class:` and every real attribute keep travelling in the hash they always travelled in — the first attempt at this fix merged the two hashes wholesale and silently dropped `data-slim-select-target`, which ten existing tests caught. A new test sweeps all nineteen group helpers rather than sampling one, because sampling is exactly how this survived: the sixteen that behaved correctly were the majority.

- **A disabled `step_number_field` no longer kills its own Stimulus controller.** The builder dropped `data-step-number-input-target` from both buttons whenever the field was disabled, and the controller declares them as required targets — so `connect()` raised `Missing target element "add"`, the controller never attached, and the console error was the least of it: a host that rendered the field disabled and enabled it later by JavaScript was left with two dead buttons, because nothing had ever wired them. The targets, the `step-number-input#add`/`#subtract` actions and the caller's own `subtract_data:`/`add_data:` are now emitted unconditionally — the same guard was silently swallowing those too, so a disabled field also lost its `data-turbo-frame`. `disabled` is what makes a button inert, and the browser needs no help with that.

  Emitting the targets is not sufficient on its own, which is the part worth knowing. `updateValue` runs during `connect` and calls `updateButtonState`, which assigns `button.disabled = atLimit`; with no `max:` the limit is `Infinity`, so the first thing the newly-connected controller would have done is **re-enable the buttons the host disabled** and strip their `btn-disabled pointer-events-none`. `updateButtonState` now ORs the input's own `disabled` into that decision, so the field stays disabled and the min/max limits keep behaving exactly as before. **What breaks:** any test or CSS asserting that a disabled step-number button carries no `data-action` or no `data-step-number-input-target` stops matching — one test in this repo did, and was inverted. The alternative fix, declaring the targets optional and guarding every access with `hasAddTarget`, was rejected: it silences the console while leaving the enable-by-JS case exactly as broken as it is today.

- **Preview only: `bali/form/datetime/with_value` returned a deterministic 500.** The preview wrote `Time.current`, and Ruby's lexical constant lookup walks the enclosing scope of `Bali::Form::Datetime::Preview` — where `Bali::Form::Time`, the module of the time-field component, shadows the top-level `Time`. `NoMethodError: undefined method 'current' for module Bali::Form::Time`. It is `::Time.current` now. Nothing in the shipped components was affected and no host ever hit this, but it was the single non-200 in a sweep of every Lookbook preview, which made that sweep useless as a signal and got it re-reported five times. The rest of the codebase was audited for the same shape by resolving every bare top-level constant reference in `app/` and `lib/` against each of its enclosing lexical namespaces: this was the only one. Sidecar and preview `.erb` templates are not exposed, since they compile against the component or view cref rather than inside the `Bali::Form` nesting.

- **Dummy only: `/sidemenu-example` had not compiled for weeks, and every page of the dummy is now asked to render.** The page carried one `<% end %>` too many — the block closing `Columns`' first `with_column` was written twice — so the template did not compile and the route answered a bare 500 (`ActionView::SyntaxErrorInTemplate`, unexpected `end`). **Nothing in the package is affected and a host that updates sees no difference**; what makes it worth an entry is that the full suite stayed green the whole time. Component tests render classes rather than pages, the Lookbook sweep only walks `/lookbook/...`, and this page is not a preview, so nothing in the repo ever requested it. `/admin/analytics` had the same blind spot from the other side in the previous release.

  So `test/requests/dummy_pages_smoke_test.rb` now walks the dummy's own GET routes and asserts each one answers — 53 of them, derived from the route set rather than from a hand-written list, with the two exceptions named and explained in an `UNSWEPT` constant. A second test fails if a route the dummy owns is neither swept nor listed, which is the part that keeps the list from rotting: a page added to the app cannot quietly go unrequested, which is the exact state that allowed this. Routes contributed by Rails, Turbo, Active Storage and ViewComponent are excluded — whether those answer is not this app's problem. The sweep found one more thing on its first run: `resources :documents` declares an `edit` route with no action behind it, which 404s (#791).

- **Dummy only: eleven call sites passed a keyword the component does not declare, and a test now refuses to let a twelfth in.** A `render Bali::X::Component.new(foo: 1)` where `foo:` is not in the signature does not raise — every component ends in `**options` and forwards the leftovers to the outer tag, so the keyword is painted as a literal `foo="1"` HTML attribute and whatever the caller meant by it silently does not happen. **None of this is a package change; a host that updates sees no difference.** But the dummy is what gets copied, so eleven examples were teaching an API that does not exist.

  **The copy button on two pages copied nothing.** `admin/analytics` and `admin/revenue` passed `text:` to `Bali::Clipboard`, whose `initialize` is *only* `**options`, and handed the icon straight to the block instead of using the slots — so the rendered widget had neither a `data-clipboard-target="source"` nor a `="button"`, and `ClipboardController#copy` reads `this.sourceTarget.innerText`. Both now use `with_source` (which takes the text **positionally**, not as a keyword) and `with_trigger`, and omit `with_success_content` so the component's own translated `bali_view.clipboard.copied` is used. Measured in the browser after the change, with `navigator.clipboard.writeText` instrumented: clicking Copy on `/admin/analytics` delivers 74 characters identical to the source element's text and the button flips to "Copied!".

  **`Bali::Tag`'s outline never applied** on `studios/index`, which passed `variant: :outline` to a component that declares `style:` — it rendered `<div class="badge tag-component badge-sm" variant="outline">`. The second site the issue listed, `studios/show`, had already been corrected in passing by #769 and needed nothing. **`Bali::StatCard` drew no delta** on the four cards of `/sidemenu-example`, which passed `change:`/`change_direction:`; the trend goes in the `footer` slot, exactly as the component's own `with_trend` preview does. **`Bali::ActionsDropdown` took a `size:`** it does not declare on `documents/show`, emitting `<div size="sm">`; the trigger is already `btn-sm` from the component, so the keyword is simply gone. And **`Bali::Avatar` took a `name:`** on `admin/analytics` — found by the new sweep, not by the issue — which put a stray `name` attribute on the wrapper and left five avatars blank; initials go through the `placeholder` slot, which is what `documents/show` in this same dummy was already doing.

  **Two Lookbook guides taught calls that do not work.** The accessibility guide offered `Bali::Button::Component.new(icon: 'x')` as the *good* example of an accessible icon button, and `Button` declares `icon_name:`. The patterns guide offered `Bali::Link::Component.new(type: :primary)` as "Link styled as button", and `type:` is precisely what #682 removed from `Link` in this release — it is `variant:` now. Both fragments are escaped (`<%%=`), so nothing rendered wrong; they were just wrong. Deliberately **not** settled here: which of `icon:` and `icon_name:` is the one true spelling. `StatCard` accepts both and has deprecated `icon_name:`, `Button` accepts only `icon_name:`, and reconciling them is #779's job — these two lines are corrected against what works *today* and will want revisiting when that lands.

  **The sweep is the deliverable.** `test/dummy_component_keywords_test.rb` compares, by reflection, the keywords of every `Bali::X::Component.new` in the dummy's views against the `initialize` parameters of the whole ancestor chain — walking the chain is not optional, since `FormPage` declares `card:` and inherits `title:`/`subtitle:`/`breadcrumbs:`/`back:`/`max_width:` from `PageComponents::Shared` through `super`, and reading only the class reports six perfectly good calls. Nothing else catches this shape: a grep cannot, because the mistake is a keyword's *absence* from a signature written elsewhere; the suite cannot, because the page still renders; and the route sweep above cannot either, because a page that renders less than it should answers 200 just as happily. Two allowlists keep it honest rather than merely quiet — `PASSTHROUGH`, the global HTML attributes any `**options` legitimately forwards, which deliberately excludes `name:` and `value:` because they are component API often enough that listing them would hide the very mistake being looked for (excluding `name:` is what surfaced the `Avatar` bug); and `KNOWN_OPTION_READERS`, for components that read `options[:foo]` on purpose, which today holds only `DataTable` and its twelve keys, each one read off the component's source rather than assumed. Verified against the unfixed views: the sweep names all eleven sites, with file, line, component and keyword.

  This is deliberately a **smoke** test — it pins that a page renders at all, not what it renders. A page that renders *less* than it should still answers 200, which is why it does not close #787: catching that shape needs a sweep of the call sites themselves, not of the responses. Two defects on this same page are accordingly left out and filed instead: the four `StatCard`s pass `change:`/`change_direction:`, which the component does not declare (#787), and the page hand-rolls its layout around a `side-menu-main-content` class that exists nowhere in the package, so the content sits underneath the fixed sidebar (#792).

- **Two Cypress specs ignored `CYPRESS_BASE_URL` and tested somebody else's server.** `page-export-links.cy.js` and `direct-upload-controller.cy.js` visit the dummy app rather than a Lookbook preview, and both wrote out `http://localhost:3001`. `CYPRESS_BASE_URL` overrides the configured `baseUrl`, which governs relative paths only — an absolute URL in `cy.visit()` goes where it says. Running the suite from a git worktree, which needs its own port, therefore sent those two specs to a different checkout's code and database, where they *passed or failed* on the wrong thing; two earlier sessions chased that as an intermittent failure before finding the cause. Both now derive the origin from `new URL(Cypress.config('baseUrl')).origin`, so one variable governs all seventeen specs. The default in `cypress.config.cjs` is unchanged, so a run from the main checkout behaves exactly as before.

### Added

- **`bali:modal:open` and `bali:drawer:open` can name the overlay they mean.** Both events now read an optional `detail.id`, and a controller answers only when that id matches its own template target's id; a trigger link can carry `data-modal-id` / `data-drawer-id` to the same effect. Without an id the event stays a broadcast handled by whichever overlay holds the targets, which is what every existing call site sends, so **nothing changes for a host that updates**. This is what makes more than one modal per page addressable: until now the only tiebreaker was to discard controllers lacking targets, which selects nothing when two candidates both have them. Note that the generated fallback ids are still not stable across renders (`modal-#{object_id}`, `drawer-#{SecureRandom.hex(4)}`), so addressing an overlay means passing `id:` / `drawer_id:` explicitly — the generated ones remain unaddressable by construction.

### Changed (breaking)

- **The legacy sweep the FormBuilder rename left behind: the submit pair, the last v2 name, the phantom `required:`, the Bulma leftovers in `forms.css`, and one place to put the Google Maps key.** Five loose ends of #677, each measured before being touched.

  **`submit_actions` becomes `submit_group`, and the bare button becomes `submit_field`.** These were the last two helpers outside the naming convention: what `submit_actions` renders — the control inside its wrapper, with the cancel control beside it — is precisely what every `<type>_group` renders, and it was the only one that said so with a name of its own. Counted across the same eight applications #675 measured, `submit_actions` has **270 call sites** (ga-apps 96, gobierno-corporativo 77, afal-apps 59, centinela-web 14, costa-norte 11, opina 6, identity 4, bali-auth 3), which makes it the busiest helper in the builder after `text_group`; it therefore keeps working for one cycle and warns through `Bali.deprecator`, the same criterion #675 applied. `f.submit` is Rails' own name and is **not** deprecated — it renders what `submit_field` renders and keeps Rails' `(value, options = {})` signature, exactly as `f.text_area` and `f.time_zone_select` do.

  **`search_field_group` becomes `search_group`, closing the one exception #675 had to leave open.** It waited for the search rework (#677 point 3, already released) so that work would not land on a name about to change. Measured before renaming: **0 call sites** across the eight applications, so there is no shim — `search_field_group` raises `NoMethodError`, which is the treatment the other seven untrafficked renames got. There is deliberately **no `search_field`**: Rails defines that name, two host call sites already call Rails' version, and taking it over — unlike `text_area`, where the override renders the same control the canonical name does — would hand those call sites a submit-button addon and a default placeholder neither asked for. The bare control for a search box is `text_field`. With this, **`.claude/CLAUDE.md`'s FormBuilder section has no exceptions left to list.**

  **`required:` stops pretending on the families that have no control to put it on.** It is a plain HTML attribute the builder forwards, not a Bali option, and on the twenty families that render a native input it lands there and the browser enforces it — unchanged. Measured helper by helper, the rest were not so honest: `coordinates_polygon_group` and `time_period_group` emitted `<div required>`, `rich_text_area_group` emitted `<trix-editor required>`, and the block editor, the rich text editor, the direct upload field and the recurrent event rule field swallowed the key without a word. None of those attributes is valid, none of them made the field required, and each of those helpers is a widget over a hidden field — which is barred from constraint validation — so there was no element any of them could have been given that would have worked. They all drop it now, through one named list in `HtmlUtils` rather than one family's private constant, and `test/bali/form_builder/required_option_test.rb` sweeps every group helper and fails if a new one lands in neither bucket. **For a host that updates, nothing that worked stops working**: what changes is that markup asserting a constraint the browser never applied is no longer emitted. One case worth knowing is not a widget at all: `radio_group`'s per-input attributes travel in `html:`, so a top-level `required:` is a group option and reaches no radio, while `html: { required: true }` reaches all of them.

  **The Bulma vocabulary comes out of `bali/forms.css`.** Every rule in that file was checked against the 480 pages this package renders and against the eight consuming applications. What matched nothing on either side is gone: `.radio input` and `.radio .field_with_errors` (in daisyUI 5 `.radio` **is** the input, and an input has no children), `.block-radio`, `.large-radio-group`, `.field-body > .field`, `.control.is-small`, `.control.inline`, `.control > .v-center`, `.control > .is-5`, `.inline-label`, `.delete-column`, the whole `.file.is-boxed` / `.file-label` / `.file-icon` family (the file field renders Tailwind utilities now), the `.togglers` / `.toggler` / `.toggler.is-active` half of `.radio-buttons-group` (the toggler row is a daisyUI `join` of `join-item btn btn-sm`), and `.label .tooltip-component` with its `.tippy-content` child. `.select.full-width` goes with them, and its measurement is the one worth repeating: the rule targets Bulma's `<div class="select"><select>` wrapper, while Bali's slim-select wrapper has been `.slim-select` since v2 — so the fifteen `select_class: "full-width"` call sites in ga-apps never reached it in **either** version, and `.ss-main` is already `w-full`. **What stays, and why the file is still unlayered**: the `@supports (appearance: base-select)` block, which has to outrank daisyUI's `@layer utilities` (#638); `.control { min-width: 0 }`; the `.field_with_errors` rules, which match 43 elements across those pages; and the five-step `.is-very-short` … `.is-very-long` width scale, the one `is-*` vocabulary with measured traffic — two call sites reach it through `class:` and four more through `alt_input_class:`, which the datepicker controller prepends `input ` to before handing it to flatpickr's altInput, so a static sweep of the rendered HTML does not see them. Prefer a Tailwind width in new code; the scale goes in 4.0. The stale example in `file-input-controller.js`'s own documentation, which described the Bulma markup the field stopped emitting, was rewritten to the markup it emits.

  **`Bali.google_maps_key` is the one place the Google Maps key comes from.** `LocationsMap` and the form builder's `coordinates_polygon` field each called `ENV.fetch("GOOGLE_MAPS_KEY")` on their own, which made the environment the only place the key could live — an application keeping credentials in `Rails.application.credentials` or in a secrets manager had to export an environment variable purely to satisfy this gem. The environment variable is still read, as the fallback rather than the source, and it is resolved per call rather than frozen at load, so **an application that only exports `GOOGLE_MAPS_KEY` behaves exactly as it did.** Verified both ways in the browser, because a missing key is precisely the failure a blank page hides. The `autocomplete-address` Stimulus controller is **not** included: it is wired by hand in the host's markup and reads its key from `data-autocomplete-address-api-key-value` or `window.GOOGLE_MAPS_API_KEY`, and it never read the environment variable whatever `docs/guides/external-services.md` claimed — the guide is corrected rather than the controller, because giving it the Ruby-side key means Bali rendering an element it does not render.

  **What is deliberately left alone.** The `date_select_group` and `check_box_group` aliases stay shimmed for this cycle. #677 asked for their removal and re-measuring says no: 7 and 3 live call sites (ga-apps, and gobierno-corporativo for one of them). #675 already did the part that mattered — they stopped being equal-citizen aliases and became deprecated shims that warn — and pulling them now would turn ten working call sites into `NoMethodError` for no gain a cycle of warnings does not give. They go in 4.0 with the rest of `DeprecatedNames`.

- **The FormBuilder becomes one family of names with one call shape.** Until now the wrapper helper was spelled `<type>_field_group` for twenty-three field types and `<type>_group` for nine, with no rule saying which — `select_group` but `text_field_group`, `text_area_group` but `date_field_group` — and the bare helper was `<type>_field` for most types, the plain Rails name for `text_area` / `rich_text_area` / `time_zone_select`, and an invented name for `rich_text` and `block_editor`. This package's own agent instructions carried a lookup table of the exceptions, which is the clearest evidence available that the API could not be guessed. There is one rule now: **`<type>_group` renders the control inside its fieldset, `<type>_field` renders the bare control.** `select_group`/`select_field` was already the right shape; twenty-three group helpers and five bare helpers moved to match it, and `currency_field`, `percentage_field` and `numeric_field` were added because those three types had a group half and no bare half at all — an amount could not be rendered outside a fieldset without hand-rolling its `inputmode` and its locale pattern.

  **Which old names survive was measured, not decided.** The eight applications that render this builder — afal-apps, ga-apps, gobierno-corporativo, centinela-web, costa-norte, identity, opina and bali-auth — were counted call site by call site: 1269 calls to the group helpers, headed by `text_field_group` at 329, `select_group` at 202 and `slim_select_group` at 197. Every renamed name any of them calls keeps working for one cycle and warns through `Bali.deprecator`; that is seventeen names, down to `month_field_group` at two. The seven renames with no measured call site anywhere (`coordinates_polygon_field_group`, `direct_upload_field_group`, `numeric_field_group`, `recurrent_event_rule_field_group`, `step_number_field_group`, `time_period_field_group` and the `datetime_select_group` alias), plus the bare `rich_text` and `block_editor`, raise `NoMethodError` instead — a deprecation warning is a migration aid for code that exists, and none does. The full table, old name to new name with its count, is in `docs/guides/migration-v2-to-v3.md`.

  **Everything after the attribute is a keyword.** Six different positional shapes collapse into one. The three select families took two anonymous positional hashes, and nothing at the call site said which of them `label:` belonged in; `boolean_field_group` and `switch_field_group` took `checked_value` and `unchecked_value` as trailing positional arguments, so binding a `"yes"`/`"no"` column meant writing `f.boolean_field_group :indie, {}, "yes", "no"` — spelling out an empty hash purely to reach past it; `radio_buttons_group` took three hashes in a row. The field's own options are keywords now and the element's attributes go in `html:`, which is the same split the two hashes always encoded, just named. The v2 positional pair is still accepted, with a warning, on the three select families only: at 399 measured call sites between `select_group` and `slim_select_group` they are the busiest surface in the package, and 28 of those calls use the positional form. `radio_*` takes the keyword form only, because none of the eight applications calls it positionally.

  **What this breaks for a host that updates.** Renamed helpers with traffic warn and keep working; the seven without traffic raise. A helper whose options now arrive as `**options` rejects an explicit positional hash, so `f.text_group :name, opts` raises `ArgumentError` where `f.text_field_group :name, opts` worked — write `f.text_group :name, **opts`. The 28 positional select calls warn rather than break. One deliberate subtlety in that shim: `f.select_group :x, values, {}, class: "w-64"` had the *trailing keywords* meaning the html hash, so the shim reads them that way; treating them as the field's options would have moved `class:` off the `<select>` silently, which is precisely the class of bug this change exists to end.

  **What this deliberately does NOT do.** `search_field_group` keeps its v2 name here. The search input was being reworked under #677 and renaming it in this change would have landed that work on a name about to change again; it joins the convention in the legacy sweep entry below, which is also in this release. `f.text_area`, `f.rich_text_area` and `f.time_zone_select` are **not** deprecated either: they are Rails' own helper names, Rails and the gems built on it call them positionally, and dropping the overrides would silently downgrade those call sites to unstyled controls — `text_area_field`, `rich_text_area_field` and `time_zone_select_field` are the canonical spellings and render exactly the same markup. `rich_text_area_field` is the one member of the family that delegates to the Rails-named override rather than the other way round, because ActionText installs `rich_text_area` from an initializer and there is nothing to alias when the file loads.

  The compatibility layer lives entirely in `lib/bali/form_builder/deprecated_names.rb` and is deleted in 4.0. It is covered by tests that call the v2 names on purpose: the rest of the suite moved to the new spellings in the same commit, so nothing in it would have noticed a shim breaking — or silently ceasing to warn.
- **One `search:` shape, one place that builds the Ransack parameter, and `Bali::SearchInput` is gone.** Quick search had four implementations that agreed only by convention. The `Filters` panel took `search: { fields: [:name, :genre] }` and derived `q[name_or_genre_cont]` itself. `SimpleFilters` took `search: { field_name: "q[name_cont]" }` — the parameter already spelled out by the caller — and was the only one of the two that understood `icon:`, while `fields:` was the only one that produced a parameter at all. `FilterForm` therefore shipped a builder for each shape (`search_config` and `simple_search_config`), and `SavedViews` wrote the `_or_` join and the `_cont` suffix out a fourth time to decide whether a shortcut was active. Moving a listing from one filter surface to the other silently dropped whichever keys the other shape lacked, and a typo in any of the four copies rendered a box that searched a different column set than the placeholder advertised — with no error anywhere.

  **`fields:` is now the only way in.** The caller declares the columns; `Bali::RansackParamName` derives `name_or_genre_cont` and `q[name_or_genre_cont]` from them, for all four call sites. `Bali::SearchConfig` is the shape itself — `fields`, `value`, `placeholder`, `label`, `icon`, `width` — and both components normalize through it, so every key is honoured by both instead of by one: `Filters` gains `label:` (an `aria-label` on the box, absent before), `icon:` (its submit button's glyph, hardcoded to `search` before) and `width:` (defaulting to the `w-full sm:w-64` it already rendered); `SimpleFilters` keeps its icon addon and its `w-48 sm:w-96` default. **A key outside that list raises `ArgumentError`**, and `field_name:` raises with the replacement written out, because the failure it would otherwise produce is a search box that submits nothing.

  **What a host has to change.** `field_name: "q[name_or_email_cont]"` becomes `fields: [:name, :email]` — grep for `field_name:` and for `simple_search_config`, which is removed; `search_config` is the single builder now and carries `icon:`, which only the deleted one did. `Bali::SearchInput::Component` is deleted along with its preview, its 17 tests, the `bali_view.search_input.*` strings and `Bali::Utils::DummyFilterForm`, the fixture that existed to feed its preview. It was never wired into `Filters`, `SimpleFilters` or `DataTable` — those render their own boxes — so it served only hosts calling it directly, and its replacement is the FormBuilder's `search_group` (still spelled `search_field_group` when this change landed, renamed in the legacy sweep entry above), which emits the same input and the same submit button from the same form object. The recipe, including the `auto_submit: true` variant, is in [the migration guide](docs/guides/migration-v2-to-v3.md) and rendered live on the dummy app's `/showcase`.

  **What this deliberately does NOT do.** It does not touch `search_field_group` itself: that helper is a form field rather than a component option, it is the *replacement* for what is being deleted, and the FormBuilder's naming convention is being reworked under #675. It does not make the search predicate configurable either — `RansackParamName::MATCHER` is `cont` because that is what all four copies hardcoded, and inventing an option none of them offered would be adding API under cover of removing it. And the two params a search submit has never carried, sorting (`q[s]`, excluded wholesale with the rest of `q`) and `page` (carried only when the component's `url:` holds it), still do not travel; that is unchanged behaviour, verified before and after, and worth its own issue rather than a silent fix here.
- **One dropdown, and `popover:` stops meaning "no keyboard".** `Bali::Dropdown` and `Bali::ActionsDropdown` rendered the same menu twice. `ActionsDropdown` reimplemented `with_item` almost line for line and kept its own `ALIGNMENTS` / `DIRECTIONS` / `WIDTHS` against Dropdown's single `align:` and boolean `wide:` — and it carried none of Dropdown's accessibility: no `data-controller="dropdown"`, so no arrow keys and no Escape; no `role="menu"` on the list; no `aria-expanded` emitted at all. It opened on daisyUI's `:focus-within` and that was the whole of it. `ActionsDropdown` is a **subclass of `Dropdown`** now whose only addition is the ⋯ trigger, so everything Dropdown has it has, and its ⋯ gains an `aria-label` it never had (an icon button with no text announces as "button" and nothing else).

  **The two position axes get a keyword each, and the old spellings raise.** `align:` is the horizontal one (`:start` default, `:center`, `:end`) and `direction:` is the side the menu opens towards (`:top`, `:bottom`, `:left`, `:right`); they compose, where the old single `align:` could spell four of the twelve pairs. `align: :left` → `align: :start`, `:right` → `align: :end`, `:top`/`:bottom` → `direction:`, `:top_end`/`:bottom_end` → both. Raising rather than resolving is not pedantry here: `:left` and `:right` are now valid values of the *other* axis, where they mean a menu opening sideways, so a quiet mapping would have moved the menu instead of failing. `wide:` raises too — `wide: true` is `width: :xl`, and `:sm`/`:md`/`:lg`/`:xl` are w-40/w-52/w-64/w-80. **The one thing that changes silently is the default:** Dropdown defaulted to `:right` and ActionsDropdown to `:start`, and `:start` survives because it is daisyUI's own. A call that passed no `align:` keeps working and moves; write `align: :end` to keep the old look. Six call sites inside this package were in that position and are now explicit.

  **`popover:` renders the same menu, moved.** It used to render something else entirely: a `HoverCard` whose content was a **string copy** of the list, dropped into `<body>` with no roles, no controller and no keyboard whatsoever. The HTML a popover dropdown serves is now byte-identical to the CSS one — same wrapper, same `<ul role="menu">`, same place in the document — and the controller *moves* that element into a tippy popper at connect. Ids, `data-turbo-confirm`, Stimulus targets and every listener travel with it, because it is the same node; `disconnect` puts it back. `.dropdown-content` stays on the panel until the moment tippy takes it, which is both what stops the menu flashing open while the dynamic `import('tippy.js')` is in flight and what makes a popover dropdown whose JavaScript never arrives degrade into the plain CSS dropdown. **What breaks for a host:** any CSS or test selector descending from `.hover-card-…` for a popover dropdown stops matching.

  **The native Popover API with CSS anchor positioning was measured and rejected**, and the number is why. daisyUI 5.7.9 does emit the support — `.dropdown{position-area:var(--anchor-v,bottom) var(--anchor-h,span-right)}` with `.dropdown[popover]{position:fixed}` — and it works: built by hand in Chrome 150 inside the dummy app's studios table, the menu landed 5 px inside the trigger's right edge and 3 px below it, unclipped by the `overflow-x-auto`. But anchor positioning only reached Baseline "newly available" in January 2026 (Firefox 147), and neutralising `position-area` and `position-anchor` to simulate an engine without it — everything else exactly as daisyUI ships it — put that same menu at **x=5, y=3: the top-left corner of the viewport, 1325 px left of and 505 px above the row it belongs to**. A row-action menu that lands in the corner of the screen is not a graceful fallback, and `popover:` is already in production in two apps, so the contract stays.

  **Escape actually closes now, in both modes.** It closed the menu and then handed focus back to the trigger, which re-opened it on the same frame through `:focus-within` — measured before the fix: after Escape, `aria-expanded="true"` with the menu still on screen. `close()` adds daisyUI's own `.dropdown-close`, which every one of its open rules is written to yield to, so the close survives the focus coming back; the alternative the old code used, blurring, does close it but drops the reader's place on the page. `aria-expanded` is no longer written by hand either: it is read off the same condition daisyUI opens on, so it cannot go stale on a path that did not run a setter. **`hoverable:` gets the controller** for the same reason — it was the one shape with none attached, so its trigger reported "collapsed" with the menu visible. A test asserting `assert_no_selector('[data-controller="dropdown"]')` on a hoverable dropdown now fails, and should be inverted.

  **Three silent no-ops go with it.** `with_item(method: :delete)` passed `method:` straight to `DeleteLink`, which has no such keyword: it fell into `**options` and painted `<button method="delete">`, an attribute a browser ignores. `tag: :button` items painted `name:` and `icon:` as HTML attributes, so the only way to label one was a block. And the item icon has one spelling now, `icon:`, for both kinds of item — `icon_name:` still works and warns. `spec/dummy` also had an `ActionsDropdown(size: :sm)` rendering `<div size="sm">`; it is gone.

  **What this deliberately does NOT do.** #641 — `POST`/`PATCH` items through `button_to`, and `with_modal_item` — is not here. It is additive API on a lambda this PR has already rewritten once, and bolting two new item kinds onto a diff that is otherwise entirely breaking makes the whole thing unreviewable; the cut is proposed on #775. The trigger also stays a `div[role="button"][tabindex="0"]` rather than becoming a real `<button>`: that is the better element, but `Trigger`'s `:menu` variant wraps arbitrary navbar content that would end up nested inside it.
  **What this deliberately does NOT do.** It does not touch `search_field_group` itself: that helper is a form field rather than a component option, it is the *replacement* for what is being deleted, and the FormBuilder's naming convention was being reworked under #675 — it is renamed to `search_group` in the legacy sweep entry above, in this same release. It does not make the search predicate configurable either — `RansackParamName::MATCHER` is `cont` because that is what all four copies hardcoded, and inventing an option none of them offered would be adding API under cover of removing it. And the two params a search submit has never carried, sorting (`q[s]`, excluded wholesale with the rest of `q`) and `page` (carried only when the component's `url:` holds it), still do not travel; that is unchanged behaviour, verified before and after, and worth its own issue rather than a silent fix here.

- **Checkboxes and toggles stop rendering their caption twice, and `label:` splits into `label:` and `text:`.** `boolean_field_group :indie` emitted a `<legend>Indie</legend>` *and* a `<span>Indie</span>` beside the box, because one `label:` fed two different captions and both rendered — a screen reader read the control out as "Indie Indie". The two captions now have a key each: **`text:`** is the caption inside the `<label>` wrapping the control, which is where a checkbox's accessible name actually comes from, so it keeps the default of the translated attribute name; **`label:`** is the `<legend>` over the fieldset, has no default, and renders only when asked for. This affects `boolean_field_group`, `check_box_group`, `switch_field_group` and the bare `boolean_field` / `switch_field`. **Every call passing `label:` to one of these means `text:` today** — leaving it is not an error and does not lose the string, but it moves that string into the legend and puts the attribute name back beside the control, which is the same duplicate wearing different words. The caption stays a `<legend>` rather than becoming the `<label for>` the other groups got: the control is already inside a `<label>`, and a second `<label for>` aimed at it does not replace that name, it concatenates with it.

  `switch_field_group` and `range_field_group` render through `FieldGroupWrapper` now instead of hand-rolling a `<fieldset>`, which is what let the split live in one place instead of three. Both gain the fieldset id derived from `field_id` — they had **none**, so two forms for the same model on one page were indistinguishable — plus `w-full`, `tooltip:`, `label: false`, `field_class:` and `field_data:`, none of which the hand-rolled wrappers supported. `range_field_group`'s caption loses `text-sm font-medium` and becomes a plain `.fieldset-legend` like every other group's; that is the visible half of the change.

  Adding `range_field_group` to the accessible-name contract sweep caught a bug nothing else had. `range_field` built its input with `@template.range_field(object_name, …)`, and handing the view helper a bare object name discarded the form index: two indexed forms emitted the same `id` **and** the same `name`, so the caption's `for` pointed at an id nobody emitted and, on submit, the second slider's value overwrote the first. It delegates through `super` now, as every other family already did. The contract test itself learned a third legitimate shape — a control named by the `<label>` wrapping it — rather than being loosened, and a companion test asserts it still reports a checkbox with neither an inline caption nor a legend, because a check that cannot fail is not a check.

- **Currency and percentage follow the active locale, and drop a `step` that never did anything.** The `pattern` validating these fields was the frozen English literal `^(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$`, so an amount typed the correct Spanish way — `1.234,56` — was rejected by the browser before it ever reached the server. Both separators now come from Rails' `number.format.delimiter` and `number.format.separator`, read at render time. Measured in Chrome by typing into `/admin/movies/new`: under `?locale=es` the field accepts `1.234,56`, which the old pattern rejects; under `?locale=en` it accepts `1,234.56`. An app without `rails-i18n` resolves to Rails' English defaults in every locale and behaves exactly as before, so this cannot regress anyone. `pattern_type: :number_with_commas` still works and now resolves this way — the name is a misnomer kept for compatibility, and `:localized_number` is its real name.

  **`step: "0.01"` is gone.** These render `type="text"` — they have to, or the thousands delimiter cannot survive being typed — and `step` is inert on a text input: it validated nothing and told whoever read the markup something false. `inputmode="decimal"` replaces it as the attribute that actually pays off, because a bare text input opens the alphabetic keyboard on a phone.

  The server half moved too, and it was the worse bug. `Bali::Concerns::NumericAttributesWithCommas` deleted commas and nothing else, so under a Spanish locale `"1.234,56"` was stored as `1.23456` — no exception, no validation error, just a number four orders of magnitude too small. It now removes the locale's delimiter and normalises its separator. **If you papered over this with a setter of your own, remove it before it double-parses.** The two families are also one implementation now (`numeric_field_group`); they had drifted into two copies of the same six lines, which is how they came to carry the same two bugs.

- **`dynamic_fields` renders `<button>` instead of `<a href="#">`.** `link_to_add_fields` and `link_to_remove_fields` emitted anchors for controls that do not navigate — the accessibility anti-pattern this repo's own guide forbids — so a screen reader announced a link going nowhere, and the `#` jumped the page to the top on any activation the Stimulus action did not swallow. The concrete breakage was the maximum-size cap: `connect()` disables the add control once the association is full, and `disabled` is inert on an `<a>`, so the cap looked enforced while the control stayed clickable. Both now spell `type="button"` explicitly, since these sit inside a `<form>` where a typeless button submits it. **Any CSS or test selecting `a.btn`, `a[href="#"]` or an `<a>` inside these stops matching.** The helpers keep their `link_to_` prefix; renaming them is a separate change. Verified in the browser: adding and removing rows still works, the URL never changes, and the page has zero `a[href="#"]` left.

- **`ImageField` stops requesting a third-party URL on every render.** The placeholder constant held `https://placehold.jp/128x128.png` while the comment directly above it claimed it was "a data URI to avoid external dependency". Every render without a `src:` — and every render *with* one too, since the placeholder `<img>` is emitted alongside whenever there is an input slot — fired a request at a host nobody in this project controls: it leaked the page's Referer, put a stranger's uptime in front of a form field, and left the component broken behind an offline or egress-filtered network. It is an inline SVG data URI now. Confirmed with Chrome's network panel on the `image_field/with_input` preview: the page makes no request outside `localhost`. Nothing to change unless you asserted on the old URL — `placeholder_url:` still works — though the placeholder art itself changes.
- **One taxonomy for every button, and `Bali::Link` finally loses `type:`.** Four components render daisyUI's `.btn` — `Button`, `Link` in button dress, `DeleteLink` and `BulkActions::Action` — and each carried its own table of modifiers. They disagreed on the axis daisyUI 5 is most careful to separate: `Button` listed `outline` next to `primary`, as if a border and a colour were the same kind of thing; `Link` spelled that same thing `style: :outline`; `DeleteLink` had neither and took only `size:`, capped at `lg`, with everything else hardcoded into a `BASE_CLASSES` string; `BulkActions::Action` kept a fourth map that was missing `link` entirely and built its size class as `"btn-#{size}"`, which Tailwind's source scanner cannot see — those classes only ever shipped because some *other* component happened to spell them out. Learning one of the four taught you nothing about the other three. There is one table now, `Bali::ButtonTaxonomy`, holding the only literal `btn-*` strings in the library, and three keywords that mean one thing each and compose: `variant:` is the colour, `style:` is the fill (`:outline`, `:soft`), `size:` is the scale (`:xs` … `:xl`). `ghost` and `link` stay under `variant:` even though daisyUI's own docs file them as styles, because that is where every call site in every host app already writes them and they are mutually exclusive with a colour in practice; the axis that moved is the one that was genuinely duplicated under two keywords.

  **What breaks.** `Bali::Link.new(type:)` **raises** — it was deprecated in v2.0, and it is rejected rather than ignored because `<a type="primary">` is valid HTML, so letting it fall through to `**options` would have rendered an attribute nobody asked for instead of the colour they did ask for. `Bali::Button.new(variant: :outline)` raises and names `style: :outline`. `Bali::Button`'s own `type:` is untouched: it always meant the HTML attribute, and that collision between two meanings of one word is exactly why `Link` lost its version. All three keywords now validate on all four components, so a name outside its table raises `ArgumentError` at construction where it used to render a button with no colour at all — the failure mode that lets a stale value survive two majors while merely looking plain. The message names the keyword that does take the value (`variant: :outline is a fill, not a colour. Use style: :outline.`) or, for a Bulma leftover, its replacement. **If you build a `variant:` from a database column or a config file, that path now raises**; check it before deploying. In this repo the validation immediately found four call sites the greps had missed, all inside multi-line renders: two in `Calendar::Header` and two in the dummy app.

  **`DeleteLink` gains the whole taxonomy and merges its two icon keywords.** `variant:`, `style:` and `size:` work on it now, and `size: :xl` exists where the private table stopped at `lg`. The default output is byte-identical (`btn btn-ghost text-error`, checked in the browser): `variant:` defaults to `:ghost`, and the destructive `text-error` is applied for `:ghost` and `:link` — the two variants with no colour of their own — and dropped for any other, because `btn-error` with `text-error` on top is red text on a red fill. `icon:` said *whether* and `icon_name:` said *which*; `icon:` now takes `true` or an icon name, and `icon_name:` warns through `Bali.deprecator` until v4. `Dropdown#with_item` and `ActionsDropdown#with_item` are unaffected — they still take `icon_name:` for every item, delete items included, and translate it, because an item is not the place to make a caller notice which of two components it is about to become.

  **A disabled `DeleteLink` is a `<button aria-disabled="true">`, not the `<a disabled>` it used to be.** HTML has no `disabled` attribute on an anchor, so that state existed only as paint. Measured in Chrome on the `delete_link/with_hovercard` preview: the v2 anchor was **not focusable at all** (`el.focus()` left `document.activeElement` on `<body>`), so a keyboard user could neither reach it nor be told anything about it, and a screen reader met an ordinary run of text where a control should be. The v3 button takes focus, carries `aria-disabled`, and does nothing on Enter or Space — checked with real key events: no navigation, no form submission, no confirm dialog, focus unmoved. Deliberately **not** `disabled` and deliberately no `tabindex="-1"`: either one takes the button out of the tab order, and with it the hover card that `disabled_hover_url` renders, which is the only place the reason for the disabled state is written. The disabled state also draws its icon now, which it used to drop. **Host CSS or system tests selecting `a[disabled]` or `a.btn-disabled` stop matching**; `.btn-disabled` still does.

  **`Bali::HoverCard`'s keyboard trigger was dead, and had always been.** Its hover mode asked tippy for `"mouseenter focus"`, but tippy only honours `focus` when the focused element *is* the reference — and the reference is the trigger slot's wrapper `<div>`, which has no tabindex and therefore never takes focus. Measured on the same preview: with `focus`, focusing the button inside the trigger left `tippy.state.isVisible` at `false`; with `focusin`, which bubbles, it is `true`, the card opens and `aria-expanded` follows. The default is `"mouseenter focusin"` now. Nothing can regress from this, because the branch it replaces could never fire; `open_on_click: true` is untouched. It is in scope because the disabled `DeleteLink` above is only meaningfully focusable if the explanation is reachable once you get there.

  **What this deliberately does NOT do.** Issue #682 also asks for `ActionsDropdown` to become a thin preset of `Dropdown` — so it stops duplicating the items without any of the keyboard handling, `aria-expanded` or roles — for `popover:` to become a positioning strategy of `Dropdown`, and for `hoverable:` to be resolved, plus #641's POST and modal items. None of that is here. `popover:` is a genuine design fork (adapt the current tippy path so the dropdown controller can drive a menu tippy clones into `<body>`, or move to the native Popover API with CSS anchor positioning and own the fallback), it needs its own Cypress coverage, and bundling it with a breaking taxonomy change makes a diff nobody can review. It is split out as #775, with the analysis and the daisyUI CSS that backs it attached, so the follow-up starts from the fork rather than rediscovering it. `Bali::Tooltip` has the identical dead-`focus` defect as `HoverCard` and is **not** fixed here, because its trigger is a caller-overridable `trigger_event:` with a documented default; it is filed as #776. `Bali::Pagination`'s private `variant:` (`:default`, `:outline`, `:ghost`) is a fifth vocabulary and is also left alone — it names link styles inside a pager, not a `.btn`.
- **`Message`, `Notification` and `FlashNotifications` become `Alert`, `Toast` and `ToastContainer`.** Three components wrapped the same daisyUI `.alert` and agreed on almost nothing. The keyword that picks a colour was `color:` in one and `type:` in another. `Message` accepted `primary`, `secondary`, `danger`, `link` and `info` for five names that resolved to *two* daisyUI classes, and fell back to `alert-info` for anything it did not recognise; `Notification` accepted a different five and fell back to `alert-success`. "Dismiss" meant a close button in `Message` (`dismissible:`) and an auto-close timer in `Notification` (`dismiss:`), and `Notification`'s close button could not actually be turned off — it was always rendered and hidden by an `is-unclosable` class nothing in the gem ever set. Every `Message` announced itself to screen readers as `role="alert"`, interrupting whatever was being read, including a purely informational banner. There are two components now: `Bali::Alert::Component` is the alert, and `Bali::Toast::Component` is an alert with a `duration:`. `Bali::ToastContainer::Component` is the fixed stack they live in, and takes the whole flash hash.

  **The old three still work and warn through `Bali.deprecator`**, translating their keywords, so an app updates at its own pace; they go in 4.0. The one behaviour that changes under the shim is the ARIA role, which is the point of the change: the role is derived from the colour now — `alert` for `error`, `status` for everything else — so only an error interrupts. Read out of Chrome's accessibility tree on a container rendering all four flash kinds: `status`, `alert`, `status`, `status`.

  `color:` takes `:neutral :info :success :warning :error` on both, and **an unknown name raises** instead of resolving to something. `dismissible:`/`is-unclosable` are a single `closable:`. `delay:` and `dismiss:` are a single `duration:` in milliseconds, where `nil` never auto-closes. `fixed:` and `position:` are gone from the alert and belong to the container, which spells its nine corners `:top_end`, `:bottom_start` and so on rather than `:top_right`. The full old-to-new table is in `docs/guides/migration-v2-to-v3.md`.

  On the JavaScript side `MessageController` and `NotificationController` are replaced by one `AlertController`, registered as `alert`; the identifiers `message` and `notification` no longer register, so hand-written `data-controller="notification"` markup in a host stops working and has to be renamed. `.slideInRight` and `.fadeOutRight` — animate.css names the package was squatting in the global namespace — are gone from `bali/general.css`, replaced by `.toast-component` and `.toast-leaving` in the toast's own sheet.
- **`Bali::Calendar::Component` drops `all_week:`, and stops reimplementing a card.** `all_week:` was deprecated in 2.x in favour of `weekdays_only:` and is now **removed**, along with the `#all_week` reader templates could call. It always meant the inverse of what it read like — `all_week: false` was the way to *hide* the weekend — and the resolution between the two spellings needed a three-branch method (`weekdays_only:` wins, else invert `all_week:`, else `false`) plus a `nil` default on a boolean to tell "not given" from "given as false". Passing `all_week:` now does nothing at all rather than raising: it lands in the `**options` the component already ignored, so **a call site left unmigrated silently gains the weekend back**. That is the one to grep for — `grep -rn "all_week:" app/` — because it fails as a layout change, not as an error. `weekdays_only:` covers every case and defaults to `false`.

  `weekly_title_class` becomes a real keyword argument. It was the only key ever read out of `**options`, plucked by name from a hash nothing else touched, so it was undocumented and untypo-able-against. Its behaviour is unchanged and it is now listed with the other parameters.

  **The component renders `Bali::Card` instead of hand-written `.card`/`.card-body` divs**, which is what the library's own composition rule asks for. The emitted markup is the same three elements with one class difference: the card carries `shadow-sm` where it carried `shadow`. Both compile to the identical `box-shadow` in Tailwind 4 — checked in the built stylesheet, the two declarations are byte-for-byte the same — so nothing moves visually. **If you wrapped the calendar in your own `Bali::Card`, remove it**; the dummy app's showcase page was doing exactly that and rendering a card inside a card. Selectors on `.calendar-component > .card > .card-body` still match, and `.month-view`/`.week-view` are still on the card element.

- **DocumentEditor / DocumentPage** - the two wrappers stop mirroring `BlockEditor`'s options and take a single `config:` instead. `DocumentEditor` re-declared **twelve** keyword arguments it never read — `ai_url`, `mentions_url`, `mentions`, `references_url`, `references_resolve_url`, `references_config`, `comments`, `export`, `export_filename`, `multi_column`, `upload_url`, `syntax_highlighting` — purely to hand them down; `DocumentPage` re-declared three of them. Adding one editor feature meant editing three signatures, three `attr_reader` lists and three render calls, and a feature wired into two of the three was indistinguishable from one deliberately left out of the third. That is not hypothetical: `DocumentPage` forwarded only the `references_*` keys, so it could never render mentions at all — not by decision, by omission, and it gains the other nine here as a side effect. The set is now one value, `Bali::BlockEditor::Config`, which `config:` accepts as either a Hash or the object. **This breaks any call site passing those keys directly to `DocumentEditor` or `DocumentPage`**; move them inside `config:`, mapping shown in `docs/guides/migration-v2-to-v3.md`. `BlockEditor::Component` itself is untouched — it keeps every keyword argument and merely gains `config:`, where an explicit keyword beats the bundle, so an app can declare its editor setup once and still turn one feature off for one editor. The precedence needs a sentinel default rather than `nil`, because `ai_url: nil` and "argument not given" are otherwise the same thing and a configured feature could never be switched back off.

- **DocumentEditor** - the REST contract stops inventing URLs and stops assuming your model is called `Document`. The controller built two of its own endpoints by string interpolation — `POST "#{document_url}/restore_version"` and `GET "#{versions_url}/#{id}"` — which made the host's routing file a guess the JavaScript was making. There is now a declared `restore_version_url:`, and each version's own JSON can carry a `url`. Both keep their old derived value as a fallback, so an app whose routes already matched needs no change; the derivation is a fallback now rather than the contract. Separately, the auto-save payload root was hardcoded to `document` and the hidden input to `document[content]`, so an app editing an `Article` had to permit `params[:document]`. Both now follow `param_key:` (default `:document`), and an explicit `input_name:` still wins. Nothing changes for an app whose model really is a `Document`. This is the last release where these are free to move: v3.1 packages a document engine on top of them.

- **RichTextEditor** - deprecated through `Bali.deprecator`, removed in 4.0. It renders exactly as it did — this is a warning, not a behaviour change — but the deprecation has to ship in 3.0 to earn the removal, and that removal is what drops roughly thirty-five `@tiptap/*` optional peers plus `lowlight` and `highlight.js` from the package. `Bali::BlockEditor::Component` reads and writes the same HTML through `html_content:` + `format: :html`, so stored content needs no migration. One option does **not** map across and the migration guide says so plainly: `images_url:` is a picker (a `GET` returning an HTML grid of already-uploaded images) while BlockEditor's `upload_url:` is a `POST` that takes one file and answers `{url:}`. Renaming it would aim an HTML endpoint at a request expecting JSON. The browse-existing-images panel has no BlockEditor equivalent at all.

- **The sidebar is operable from the keyboard, and the hamburger stops being three markups with two mechanisms.** Opening the sidebar on mobile and collapsing it on desktop were `<input type="checkbox" class="hidden">` flipped by `<label for=…>`. A label for a `display: none` checkbox is not in the tab order and has no accessible role, so the primary navigation of every app built on `AppLayout` was **unreachable without a pointer** below `lg`. Both states are now classes `SideMenuController` owns — `is-active` for the drawer, `is-collapsed` for the icon rail — and every control that touches them is a real `<button>`.

  **`Bali::SideMenu::Trigger::Component` is new and is the only hamburger.** `Topbar`, `AppLayout`'s fallback mobile chrome and `Navbar::Burger(type: :sidebar)` all render it instead of their own markup. It carries `aria-controls` pointing at the sidebar's id, `aria-expanded` kept in sync by listening for the state event the sidebar broadcasts, and it travels with the open event so the sidebar can hand focus back to *that* button when it closes. The full cycle, walked with a physical keyboard in Chrome at 375px on `/admin/movies` and on the new `side_menu/with_trigger` preview: Tab reaches the button, Enter or Space opens the drawer and focus lands on its first control, Tab cycles the items and wraps at the end instead of walking behind the scrim, Escape closes it and focus is back on the hamburger. At 1280px the same walk reaches the collapse toggle and Space collapses the sidebar to the 3.5rem rail.

  **What breaks.** `Bali::SideMenu::Component::MOBILE_TRIGGER_ID` is gone; its replacement is `DEFAULT_ID` (`"side-menu"`), which is now the sidebar's DOM `id` rather than a checkbox's. `SideMenu.new(mobile_trigger_id:)` is now `id:`, and `Topbar.new(mobile_trigger_id:)` is now `menu_id:` — `nil` still means "no hamburger". `Navbar::Burger.new(trigger_id:)` is now `menu_id:`. The `.side-menu-mobile-trigger` and `.side-menu-collapse-trigger` checkboxes no longer exist, so **any CSS or test selecting on `:checked` for them stops matching** — including `:has(.side-menu-collapse-trigger:checked)`, which is how `AppLayout` used to narrow its content offset and which now reads `:has(.side-menu-component.is-collapsed)`. The i18n keys `bali_view.side_menu.toggle_mobile` and `.toggle_collapse` are removed, `.label` and `.trigger.toggle` added, plus `bali_view.app_layout.skip_to_content`.

  **`AppLayout(fixed_sidebar:)` defaults to `true`,** because `false` contradicted `SideMenu(fixed: true)` and the two defaults together produced a pinned sidebar overlaying content that was never offset for it — broken out of the box, silently. The slot takes arbitrary markup (`render "layouts/admin_sidebar"`), so the layout cannot configure the sidebar; what it can do is read what the slot rendered, and it now **raises in development and test** when it positively identifies a Bali `SideMenu` whose `fixed:` disagrees. Custom sidebars are untouched by the check. Two consequences of the flip: `viewport_locked:` now defaults to whether a fixed sidebar was *actually rendered* rather than to the raw flag, so `fixed_sidebar: true` with an empty slot no longer locks the viewport for a sidebar that is not there; and a host relying on `fixed_sidebar: false` must now pass it explicitly *and* pass `fixed: false` to its `SideMenu`.

  **Landmarks and list semantics.** `SideMenu` renders `<nav aria-label>` (was a `div`), its sections are `ul`/`li` (were `div`s), and the link pointing at the current page carries `aria-current="page"` — verified on `/admin/movies`, exactly one visible occurrence. An active *ancestor* keeps its highlight but does not get `aria-current`; that belongs to the link that actually points at the page. Section titles stay `<p class="menu-label">` on purpose: the sidebar renders before `<main>`, so headings here would land above the page's own `h1` and break the outline — the other half of the `PageHeader` fix below. `Topbar` renders `<header>`, the page's banner. `AppLayout` renders a skip link as the first focusable element of the page, off-screen until focused, pointing at the `<main id="main-content" tabindex="-1">` it also renders now; `skip_link: false` opts out.

  **The closed drawer is taken out of the tab order by `inert`, not by CSS, and that choice was measured.** `translateX(-100%)` alone left every link in it focusable. The obvious fix — `visibility: hidden` on the closed panel, revealed by the `.is-active` rule — makes focusability depend on the animation clock: the panel is still un-focusable in the task that opened it, so `focus()` runs and silently does nothing, and the drawer opens with focus parked on the trigger. Forcing a synchronous style and layout flush first does not help. `inert` is a DOM attribute and applies the moment it is removed. The component renders it on every fixed sidebar so the pre-connect drawer is already out of the way, and the controller drops it at desktop widths on connect and on every crossing of the breakpoint.

  **Also fixed, from the same issue:** an untitled first section had no top gap and its first item sat flush against the chrome row's border, which consuming apps were patching themselves; `.sidebar-menu > .side-menu-list:first-child` now carries the `pt-3` a titled section gets from its label.
  **What this deliberately does NOT do.** `NavbarController#toggleSideMenu` stays: it dispatches the same `bali:side-menu:toggle` window event the trigger does, so it is the same mechanism through a second entry point, not a second mechanism — but a control wired to it directly gets no `aria-expanded` and no focus restoration, so prefer the trigger. The two collapse buttons each carry a static `aria-expanded`, because the expanded and collapsed headers are mutually exclusive and CSS shows exactly one, so the button in the accessibility tree always has the true value; collapsing that to one button needs the header markup merged, which is a larger change. And the drawer is a focus trap by keyboard only — it does not set `aria-modal` or lock body scroll, which is `Modal`'s job and not settled for a navigation drawer.

- **`PageHeader` stops emitting empty headings, names the page with an `h1`, and stacks properly under `sm`.** Measured on the twenty page-component previews at 375px and 1280px: **ten empty heading elements before, zero after; zero of the forty pages had an `h1`, all forty-two do now** (the count includes a new preview). Two separate defects sat in the same six lines of template.

  **The empty headings.** The template rendered `tag.h6(@subtitle, class: subtitle_classes)` unconditionally, so every page built without a subtitle shipped `<h6 class="subtitle"></h6>` — an axe violation, and a section with no name in the document outline. The title had the same shape, and the block form had a worse one: the slot wrapped the block in a heading, so the documented `with_title { tag.h3(...) }` produced an `h3` inside an `h3`, which the HTML parser splits into an empty heading plus yours. That preview alone accounted for two of the ten. Nothing renders now unless there is text or a block, and the block-form preview no longer teaches nesting a heading inside a heading.

  **The heading levels.** The title defaults to `tag: :h1` (was `h3`) and the subtitle renders as a `<p>` (was `h6`). A subtitle describes the title; it does not open a section, and as an `h6` it opened one with no content — and skipped h4 and h5 to get there. **If your layout already renders the page's `h1`, pass `tag: :h2`** or you will have two; the details are in [the migration guide](docs/guides/migration-v2-to-v3.md).

  **`tag:` no longer picks the size.** The slot used to derive the font size from the heading level through a `HEADING_SIZES` table, which made the semantic fix a visual one: defaulting to `h1` would have jumped every page title from `text-2xl` to `text-4xl`, and the `tag: :h2` migration above would then have shrunk it to `text-3xl` — a host doing the accessible thing would have been paid in a layout change. `tag:` is now semantic only, the size lives in `TITLE_CLASSES`/`SUBTITLE_CLASSES`, and `class:` overrides it. **`Bali::PageHeader::Component::HEADING_SIZES` is gone**; if you read it, the six values were `text-4xl`/`text-3xl`/`text-2xl`/`text-xl`/`text-lg`/`text-base`. The rendered size of every existing page is unchanged: `text-2xl`, what the `h3` already produced.

  **Title tags move out of the heading.** `title_tags` is now a slot on `PageHeader` itself and its badges render as SIBLINGS of the heading rather than inside it. Inside, they were part of the heading's accessible name — a screen reader announced "The Matrix Action Released" — and a `div` inside an `h1` is invalid HTML besides. The row also wraps now, so a badge drops below the title instead of squeezing it: at 375px two badges cut the title down to 277px of the 343px available.

  **The responsive stacking, which is the part a 1280px diff cannot see.** Under `sm` the back button takes a row of its own instead of standing in a gutter beside the title. Inline it cost the title that gutter on *every* wrapped line — measured at 375px, the title got 291px of 343px and started 52px in from the page's left edge, so it did not line up with the breadcrumb above it or the body below it. Now every page-component preview starts its title at x=16 like everything else on the page. **The cost is 44px of header height** (a 36px tap target plus its gap) on mobile pages that have a back button; that is the trade, and it only applies below `sm` — desktop geometry is byte-identical. This is aimed at the `+phone` template forks in consuming apps, but note the honest limit: it fixes the header, not whatever else those templates fork.

  **The back button gets an accessible name.** It is an icon-only link, so it had none — an anonymous node. It now carries `aria-label` from `bali_view.page_header.back` ("Go back" / "Volver"), skipped when you pass a visible `name:` so the accessible name keeps matching the visible one. **`Bali::Icon` renders `aria-hidden="true"` by default**, on the wrapper rather than the SVG: Lucide already hid its own `<svg>`, but the kept, custom and legacy icon sources never did, so the attribute covers all four where it sits now. Pass `"aria-hidden": false` to opt out.

  **What this deliberately does NOT do.** `PageHeader` still renders through `Bali::Level`, which is deprecated for 4.0 and whose `max-sm:flex-wrap` has never fired; replacing it changes the `.level`, `.level-left` and `.level-right` hooks in the output and is separable from this fix. `Bali::BooleanIcon` still conveys true/false through an icon alone and is still anonymous to a screen reader — it was already, because Lucide's `aria-hidden` predates this change; giving it a name is its own fix. `SideMenu` and `AppLayout`, which is where a second `h1` would come from, are #686.

- **Every `*_field_group` was an input with no name, and now the caption actually names its control.** A `<legend>` names the `<fieldset>`, not the control inside it, so for a group holding one input it named nothing a screen reader would read out — WCAG 1.3.1 and 4.1.2, across the entire form surface of every consuming app. Measured, not inferred: Chromium's own accessibility tree over CDP (`Accessibility.queryAXTree`) across the 177 form-bearing Lookbook previews, plus `/admin/movies/new`. The caption is now a `<label for>` in the 18 families that wrap exactly one labelable control, and stays a `<legend>` in the six where the group really does hold several controls — `boolean_field_group`, both radio groups, `coordinates_polygon_field_group`, `block_editor_group`, `rich_text_area_group`, `direct_upload_field_group`, `recurrent_event_rule_field_group` — because a second `<label for>` on a control that already has one does not replace its name, it concatenates with it ("Active Active"). `RangeFields` builds its own fieldset rather than going through the wrapper and had the same defect; it is fixed in the same shape.

  **The wrapper and the field helper share one derived id instead of each guessing.** `HtmlUtils#control_id` resolves `id:`, then `input_id:` (the non-model escape hatch of #547), then Rails' `field_id`, and both the `for` and the input read it from there. A `for` pointing at an id nobody emits looks perfect in the HTML and gives the control no name at all, which is exactly why this is asserted from the accessibility tree and not from the markup. `FieldGroupWrapper` takes the id as `options[:control_id]` — `false` keeps the `<legend>`, absent derives it — and **not** as a keyword argument: the last parameter is a positional Hash, so a keyword there swallows `label:`, `class:` and `type:` out of every existing call site.

  **`aria-describedby` and `aria-invalid` are wired, from what is really rendered.** #676 gave the error and help paragraphs ids; the control now points at them, and only at the ones that exist — the error id only when the field has an error, the help id only when `help:` was passed. `aria-invalid="true"` accompanies the error. Both spellings a caller might use (`aria: { invalid: }` and `"aria-invalid" =>`) are checked before anything is added, because writing both emits the attribute twice. Covered on text, textarea, select, SlimSelect, time-zone select, checkbox, toggle, radio and range.

  **Three sources of duplicate ids are gone, and the case that produced them is now a preview.** `field-#{method}` on the fieldset, `#{method}_select_div` on SlimSelect's wrapper and `#{method}_period` on the time-period select all ignored the object name, the index and any nested-attribute path, so two forms for the same model on one page emitted each of them twice. All three derive from `field_id` now, as does `RecurrentEventRuleForm`, whose dozen `select_tag`/`number_field_tag` controls carried page-global ids (`freq`, `interval`, `bymonth`…) repeated by any second recurrence form — and whose radio prefix was a `SecureRandom.hex(4)` that changed on every render, which no `<label for>`, test or Turbo morph can follow. Measured on the new `field_group_wrapper/two_forms_same_model` preview: zero repeated ids, zero dangling `for`/`aria-*` references, and each of the ten controls reading out its own name.

  **Icon-only controls get names, and flatpickr's replacement input inherits one.** The three icon-only search submits (`search_group`, `Filters`, `SearchInput`) were announced as a bare "button"; they carry an i18n'd `aria-label` now, as do the twelve unlabelled selects and number inputs of the recurrence builder. `SimpleFilters`' captions were `<label>` elements with no `for`, which name nothing: they are a `<label for>` over a single control and a `<span>` naming a `role="group"` over several. And with `altInput` on — the default — flatpickr builds a **new** input, copies only the placeholder, disabled, required and tabIndex across, and turns the original into `type="hidden"`; the `<label for>`, `aria-describedby` and `aria-invalid` therefore all stopped applying to the field the user actually types into. `DatepickerController` forwards them by hand after init.

  **What breaks for a host that updates.** The caption element changes: any CSS or system test selecting `legend.fieldset-legend` stops matching for those 18 families (`label.fieldset-legend` now), and `fieldset#field-<method>`, `##{method}_select_div` and `##{method}_period` stop matching at all. **There is a 6 px layout consequence, measured rather than assumed:** daisyUI's `.fieldset` is `display: grid` with `gap: .375rem` and `padding-block: .25rem`, and a rendered `<legend>` is not a grid item — it sits above the anonymous grid box and escapes both. A `<label>` is an ordinary grid item, so the caption drops 4 px and each field group grows 6 px taller (126 → 132 px on `form/text/with_help_text_and_errors`). No CSS neutralises it on purpose: daisyUI exposes no custom property for either value, so the fix would be a hard-coded copy of two of its literals in an unlayered sheet, which is the drift trap the CSS guide warns about. Two smaller ones: the wrapping `<label>` around a checkbox and a toggle loses its `for` — the implicit association names them instead, which survives both a repeated attribute and a caller-supplied `id:`, neither of which an explicit `for` survives — and `RecurrentEventRuleForm` gains an `id:` option that renames its controls without reaching the wrapper.

  **What is left unnamed, and why.** One control: BlockNote's ProseMirror `contenteditable`, which the editor creates client-side, so at render time there is no id for a `for` to point at and naming it needs an `aria-labelledby` written by the editor once it mounts. SlimSelect's own dropdown search input and its `role="combobox"` trigger are named by the library, not by Bali. The bare `*_field` helpers (`step_number_field` and friends) have never rendered a caption — that is the `_group` variant's job — and are unchanged.
- **Every overlay reads its z-index from one documented scale, and every old number changes.** Each overlay used to pick its own: dropdown `50`, drawer `60` on the root and `9999` on the panel, modal `61`, command palette `100`/`101`, toast `101`, hovercard `9999`, flatpickr's calendar `99999`, SlimSelect's list `10000`, BlockNote's portaled menus `9999 !important`. Nothing related those numbers to each other, so ordering two overlays was guesswork and the only reliable move was to outbid the largest one you could find — which is literally what happened when identity needed a toast above a modal and wrote `!z-[10001]`. There are now seven tokens in `app/assets/stylesheets/bali/z_index.css`, a hundred apart so a host can slot its own overlay between two of them: `--bali-z-dropdown: 200`, `--bali-z-drawer: 300`, `--bali-z-modal: 400`, `--bali-z-command: 500`, `--bali-z-popover: 600`, `--bali-z-toast: 700`, `--bali-z-tooltip: 800`. The per-component mapping is in [the migration guide](docs/guides/migration-v2-to-v3.md).

  **`--bali-z-popover` is the tier that is not obvious, and it is the one that was load-bearing.** flatpickr's calendar, SlimSelect's list, `Status`' panel and BlockNote's menus all portal themselves to `<body>`, which is exactly why they carried the absurd numbers: a date field inside a modal has to render *above* that modal or the field is unusable. They sit at 600, above `command` and below `toast`, so opening a datepicker from inside a dialog still works and a notification still covers it.

  **What breaks is any host CSS written against the old numbers.** A rule that put something at `z-70` to clear Bali's modal at `61` now sits under every Bali overlay; `!z-[10001]` still wins but no longer needs to. The fix is to read the token instead of a number — `z-[calc(var(--bali-z-toast)_+_1)]` — or to move the whole scale by redeclaring the tokens.

  **The tokens are declared as `:where(:root)` inside `@layer theme` so that a host can actually beat them.** Nothing else in the cascade declares `--bali-z-*`, so this file has nothing to outrank and every reason to be easy to override: `theme` is the first layer Tailwind declares and `:where()` carries zero specificity, so a plain `:root` in the host's `@theme {}` block wins on specificity within the same layer, an unlayered `:root` wins by being unlayered, and a `z-*` utility on the element still beats all of it. Measured in the browser, both ways. This is deliberately *not* where the daisyUI structural fallbacks in `general.css` live — those sit in a later position and cannot be overridden from `@theme {}` at all.

  **App chrome stays out of the scale, below it.** `Navbar`'s sticky bar (50), `SideMenu`'s fixed rail (40) and its mobile scrim (30), and the floating bulk-action bars (40/50) keep their numbers: they are page furniture, and the scale starting at 200 is what guarantees every overlay covers them. Intra-component stacking that never competes with another overlay — a tippy arrow at `z-[1]`, a Gantt resize handle at `z-[2]`, flatpickr's own nav arrows at 3 — is untouched for the same reason.

- **`Bali::HoverCard::Component::DEFAULT_Z_INDEX` is gone**, and `z_index:` now defaults to `nil`. The constant was `9999`; hardcoding the scale's top value in Ruby would have meant a host moving `--bali-z-tooltip` got no change in its hovercards. With no `z_index:` the component emits no `data-hovercard-z-index-value` at all and the controller resolves `--bali-z-tooltip` at connect time; passing `z_index:` explicitly still wins, unchanged. `Bali::Tooltip` gained the same behaviour — it never passed a z-index and was silently taking tippy.js's own `9999` default. Both go through `app/assets/javascripts/bali/utils/z-index.js`, which exists because tippy writes the value as an inline style and an inline style cannot hold a `var()` reference.

- **Every public event is renamed to `bali:<component>:<event>`, and the `useDispatch` mixin is deleted.** v2 emitted three generations of naming at once: `bali:command:*` and `bali:side-menu:*` were already prefixed, `openModal` / `openDrawer` / `modal:success` had no prefix at all, and the rest rode Stimulus' default `<identifier>:<name>` — `hovercard:show`, `sortable-list:onEnd`, `interact:onDragEnd`, `direct-upload:complete`. Fourteen events are renamed; the old→new table, naming the emitter and the element each is dispatched on, is in [the migration guide](docs/guides/migration-v2-to-v3.md). Five were already correct and are untouched.

  **This is the breaking change with no error message.** A renamed event does not throw, does not fail a test and does not log: the listener simply stops running and the feature quietly stops working. That is why the change was driven off a full inventory of `dispatch(` / `new CustomEvent` / `addEventListener(` across `app/`, and why every renamed emitter has its in-package listener moved in the same commit — the `document` listeners the modal and drawer install on themselves. The seven `data-action` descriptors that `Bali::GanttChart` carried were the other set, and that component is gone in v3, so nothing in the package listens for the `interact:*` events any more. The migration guide leads with the greps a host should run before upgrading.

  **`useDispatch` overwrote Stimulus' own `dispatch` with an incompatible signature**, which is why the naming could never converge. The mixin installed `dispatch(name, detail)` on the controller instance; native Stimulus is `dispatch(name, { detail, target, prefix, bubbles, cancelable })`. A controller written against the Stimulus documentation therefore produced an event whose `detail` was the entire options object and whose name still came from the mixin's own prefixing rule, and nothing anywhere said so. `app/assets/javascripts/bali/utils/use-dispatch.js` is deleted along with its `bali-view-components/utils` export, its importmap pin, and `window.baliDispatchDebugEnabled`; the migration guide carries a console snippet that traces every `bali:` event without any cooperation from the controllers.

  **The prefix is a hardcoded per-controller constant, not `this.identifier`.** Letting it default would mean a host registering `ModalController` under `my-modal` silently emits `my-modal:open` — the documented event name would depend on the host's registration table. `GanttChartController` also called `useDispatch(this)` and never dispatched anything; that dead import is gone too.

  **Two payload changes ride along.** `event.detail.controller` disappears: the mixin pushed the emitting controller instance into every payload and native `dispatch` does not. And `bali:modal:success` fires for drawers as well — not new behaviour, since `DrawerController` has always inherited `submit` from `ModalController`, but the prefixed name makes the missing `bali:drawer:success` look deliberate, which it is.

  **No compatibility aliases, deliberately.** These events split into ones Bali emits and ones Bali listens for, and those need opposite shims, so emitting both names would have covered barely half the surface while reading as full coverage. Keeping a dual-listen on `openModal` would let a host upgrade without ever learning it has to migrate, which only relocates this same break to v4.

- **A field's help text no longer disappears the moment the field is wrong, and four copies of the error message become one.** `HtmlUtils#help_message_for` was an `if errors? … elsif help`, so the instruction ("500 characters at most") was replaced by the error ("is too long") at the one moment the user needed both. Alongside it, three families had grown their own message renderer with its own class string: `BooleanFields#append_error_message`, `SwitchFields#append_switch_error_message`, and an inline `content_tag(:p, …, class: "label-text-alt text-error mt-1")` in `RangeFields#range_field`. None of those three rendered `help:` **at all**, and a `text_area` with `char_counter:` or `auto_grow:` rendered neither help nor error, because `wrap_with_stimulus` replaced the `field_helper` path that would have emitted them. There is now one `HtmlUtils#error_and_help(method, options)` and every family goes through it — `test/bali/form_builder/error_and_help_test.rb` sweeps all **18** of them and asserts each renders exactly one error paragraph and exactly one help paragraph, so no family can quietly opt out again. Both messages render, error first, so the error stays where it has always been: directly under the control.

  **Each message now carries an id** — `field_id(method, "error")` and `field_id(method, "help")`, i.e. `movie_synopsis_error` / `movie_synopsis_help`, derived with Rails' own `field_id` so they follow the same namespace, index and nested-attribute rules as the control they describe. Emitting them is all this change does; pointing the input's `aria-describedby` at them is #674.

  **The dead daisyUI 4 classes go, and the measurement is the reason.** `label-text`, `label-text-alt`, `input-bordered`, `textarea-bordered` and `form-control` have **zero** definitions in the compiled CSS (grepped over `spec/dummy/app/assets/builds/tailwind.css` after a build against daisyUI 5.7.9) — daisyUI 5 dropped all five, so they had been decorating the markup and styling nothing. The two message paragraphs move to `fieldset-label`, daisyUI 5's live successor for text under a control; the spans next to a checkbox, toggle and radio lose their class entirely, because the surrounding `.label` already styles them in daisyUI 5's own markup; and the textarea counter keeps `text-end w-full` without `label-text-alt` for the same reason. `fieldset-label` and not `.label`, measured in a 200 px container: `.label` is `display: inline-flex` with `white-space: nowrap`, so "Synopsis is too long (maximum is 500 characters)" laid out **361 px wide inside a 200 px box**, while `fieldset-label` is a block flex container with no nowrap and wrapped to 200 × 72 px.

  **What breaks for a host that updates.** Nothing renders differently — classes with no definitions have no styling to lose — but any CSS or system test that *selects* by them stops matching: `.label-text`, `.label-text-alt`, `input.input-bordered`, `textarea.textarea-bordered`, `.form-control`. In this repo that was 41 assertions across 13 FormBuilder test files. Two smaller consequences: `RangeFields` loses the `mt-1` that its error paragraph alone carried (the `.fieldset` grid's own `gap` covers it, and every other family already relied on that), and a field with both help and error now renders two paragraphs where a host's test may have counted one.

  **`select-bordered` deliberately stays.** It is the one class from the issue's list that is *not* dead: it has 8 definitions in the compiled CSS, all of them Bali's own SlimSelect compatibility selectors in `app/assets/stylesheets/bali/slim_select.css` (`.slim-select select.select-bordered`, `.ss-main.select-bordered`, `.ss-content.select-bordered`). Removing it from `SelectFields`, `SlimSelectFields`, `TimeZoneSelectFields` and `TimePeriodFields` means editing an unlayered stylesheet whose header documents what it has to outrank, and re-verifying SlimSelect end to end; that is its own change. The same goes for the ~35 occurrences of the dead classes still in shipped components (`Filters`, `SimpleFilters`, `SearchInput`, `RecurrentEventRuleForm`, `SavedViews`, `ColumnSelector`) and the ~58 in Lookbook preview templates: this change is scoped to the FormBuilder, which is where the four implementations lived.

- **The FormBuilder stops leaking its own options into the DOM, and stops mutating the caller's hash.** The helpers read `label:`, `help:`, `mode:`, `control_class:` and some thirty other keys through a `delete` scattered across each module, and handed Rails whatever survived that `delete` — and Rails forwards any key it does not recognise straight onto the element. Measured on real render, the result was `<input label="Title" help="Max 80" control_class="w-full" mode="range" pattern_type="number_with_commas">` in **20 of 20** input helpers, `select_field`, `slim_select_field` and `time_zone_select` included. There is now one list, `HtmlUtils::RESERVED_OPTIONS`, and one extraction point, `html_attributes`, that everything delegating to Rails goes through; no module keeps its own `delete`. The list deliberately separates what Bali consumes from what is a real HTML attribute: `class`, `type`, `value`, `required`, `placeholder`, `min`, `max`, `step`, `multiple`, `disabled` and `data` still reach the element, and `size` and `color` are **not** in the global list — on a `text_field` they are legitimate attributes even though on a checkbox they name daisyUI variants, so they are stripped next to the helper that gives them that meaning.

  **The mutation was the more expensive of the two defects.** `field_options` wrote `options[:class] = "input input-bordered w-full #{options[:class]}"` onto the caller's hash, so reusing one hash across two fields accumulated the first field's classes into the second, and a frozen hash blew up with `FrozenError` in 12 of 20 helpers. Every `with_defaults!` on a user hash and every `delete` on the received hash is gone. Watch the case a `dup` does not fix: `prepend_action` and friends mutate the **nested `:data` hash**, which `dup`, `except` and `merge` all keep sharing with the caller — hence `dup_options`, which copies that one key, on the seven paths that call `prepend_*`.

  **What breaks for a host upgrading.** If any CSS or integration test selects on those invalid attributes (`input[mode="range"]`, `[control_class]`, `[help]`), it stops matching: they are no longer emitted. Unlikely — no validator accepts them and nobody would write them by hand — but it is the only observable change in the HTML of a form that already worked; the rest of the markup is identical, verified by diffing the Lookbook form previews before and after. Two side effects that do change behaviour: the actions row respects `show_cancel_button?` again when `Bali.native_app` is on and `modal:` is passed (the button helper used to delete `:modal` from the hash before the check read it, so the cancel button always showed), and the button under `Bali.native_app` stops emitting `modal="true"` and `drawer="true"` on the `<button>`.
- **The package's CSS gets three deliberate cascade positions, and host utility classes finally win.** Every stylesheet Bali shipped was unlayered, which in Tailwind v4 beats *every* layer — so a component's `@apply flex` on `.menu-item` outranked a `lg:hidden` from the host's own template, and the documented workaround was to reach for `lg:!hidden`. Those `!` variants are gone from the repo, all three of them, and the gotcha they existed for is gone with them.

  **The plan this issue started from would have broken things, and the measurement is why.** daisyUI 5 does not use `@layer components` — in the compiled stylesheet that layer is an empty 18-byte declaration, and daisyUI's own `.btn`, `.card`, `.dropdown` are emitted *inside* `@layer utilities` under `daisyui.l1.l2.l3` sublayers. Since a layer beats specificity outright, moving all of Bali's CSS into `components` would have put it below daisyUI as well as below the host, measurably breaking the collapsed sidebar's flyout, the `appearance: base-select` fix from #638, the breadcrumb padding fix from #530, and flatpickr's `.inline` / `.static` calendars — those two state classes collide by name with the real Tailwind utilities `.inline{display:inline}` and `.static{position:static}`. So the split is by *what a rule is for*, not by what file it lives in:

  | Position | What | Why |
  |---|---|---|
  | `@layer base`, `:where(:root)` | `bali/theme-fallbacks.css` — the 8 daisyUI structural tokens | Zero specificity in daisyUI's own layer: a real theme in that layer wins |
  | `@layer components` | Bali's own look — 15 component sheets, 8 global ones | Host utilities beat it. This is the point of the change |
  | unlayered | `forms.css`, `datepicker.css`, `slim_select.css`, `container-overrides.css`, `breadcrumb`, `data_table`, and `daisyui-overrides.css` for `side_menu`, `calendar` and `rich_text_editor` | The only rules whose job is to outrank daisyUI — or, for the container, Tailwind itself |

  **`--border`, `--radius-box` and friends stop overriding your theme.** They were declared on an unlayered `:root` as "fallbacks for custom themes", but unlayered beats daisyUI's `@layer base`, so they won against *every* theme. That was invisible only because `light` and `dark` happen to use exactly those values — the other 33 built-in themes do not (`cyberpunk` sets `--radius-box: 0`, `cupcake` `--border: 2px`, `corporate` `--depth: 0`). They now live in `@layer base` on `:where(:root)`, specificity zero, which is what a fallback actually means. An app on a non-default daisyUI theme will see its own radii and borders for the first time.

  **One caveat on overriding those eight tokens, because `@theme {}` does not work for them.** Specificity only settles ties *inside* a layer; across layers the later one wins outright, and Tailwind orders them `theme < base < components < utilities` with unlayered CSS last. `@theme {}` — the idiomatic way to declare tokens in Tailwind v4 — compiles to `@layer theme`, which comes *before* `base`, so it loses to the fallbacks no matter how specific its selector is. Measured against `--radius-box` (fallback `.5rem`): `@theme` → `.5rem` (ignored), `@layer base { :root }` → applies, `@layer base { [data-theme] }` → applies, plain unlayered `:root` → applies. This is not specific to Bali — daisyUI's built-in themes live in `base` and shadow an `@theme` block in exactly the same way. Override these eight from a daisyUI theme, a `@layer base` block, or an unlayered `:root`.

  **`SideMenu` is split in two files.** `index.css` moved into the layer; the eight rules that exist to outrank daisyUI (`.dropdown-content` positioning, `.collapse-title` min-height, `.menu .menu-item` layout) moved to `side_menu/daisyui-overrides.css`, unlayered, with a header naming the daisyUI rule each one beats and a rule of thumb for what may be added there. No new `!important`: putting one inside a layer would have made it nearly unbeatable from a host, which is the opposite of what you want — an unlayered `!important` is the *weakest* important in the author origin, so a host escapes it with a `!` variant, and a layered one it cannot.

  **One import, not two.** `bali.css` now imports `bali/components.css`, so a host has a single entry; forgetting the second one used to leave every component unstyled with no error. `./css/components.css` stays exported for anyone who wants only that half. `bali/variables.css` — empty, published, imported by nobody — is deleted.

  **Three visual changes ship on purpose,** all cases where the template already asked for a value and the CSS was silently overriding it: the SideMenu collapse button is 32px instead of 36 (its `p-2` applies now), the active item in the DataTable's saved-views dropdown renders in `text-primary`, and the Navbar has `shadow-sm` instead of `shadow-md`. Verified by diffing computed styles across every preview against a pristine baseline: every difference is one of these.

  **Six rules had to move a second time, because a layer swallowed them.** The first pass put them where the file lived rather than where the rule had to win, and the preview sweep could not see it: three of the six only appear in a state (a hovered row, a keyboard-highlighted row), one only above 1024px, one only with `ENABLE_RICH_TEXT_EDITOR=1`, and one on a class no component in this repo uses. `Bali::Command`'s `density: :compact` was inert end to end — every dimension it sets was pinned by a static utility on its own template — as was `.cmd-row.is-active` under the cursor; both are fixed by moving those template defaults into `command/index.css` next to the rules that override them. `.container.is-not-fluid`, public API for host apps, stopped capping at 960px because Tailwind's own `.container` utility outranked it, and now ships unlayered in `bali/container-overrides.css`. Calendar cells lost their `base-300` grid line to daisyUI's `.table` row rule, `.rich-text-editor-component.input` lost `display: block` (and, when read-only, its border, shadow and padding reset) to daisyUI's `.input`, and every `.menu-item` inside a `.menu` lost its hover background, its active tint under the cursor and its `transition-property` — each now has a `daisyui-overrides.css` beside its component naming the daisyUI rule it beats.
- **One pagination footer, one summary key, and one place that talks to Pagy.** The library had three implementations of the same "summary on the left, controls on the right" band: `Bali::PaginationFooter`, an inline copy of it at the bottom of `Bali::DataTable`, and `Bali::Pagination` underneath both. Two of them derived the summary sentence separately, so it had two i18n keys — `bali_view.data_table.summary` and `bali_view.pagination_footer.summary` — for one string, and a host translating a listing had to find both. `DataTable` now renders `PaginationFooter`; the inline footer is gone, and the surviving key is **`bali_view.pagination.summary`**, with `bali_view.pagination.default_item_name` next to it, both in en and es. If you override either, that is the path now: `bali_view.data_table.summary`, `bali_view.data_table.default_item_name` and the whole `bali_view.pagination_footer.*` subtree no longer resolve to anything.

  **A summary of zero results is gone, not empty.** With `count == 0` the footer used to print "Showing 0-0 of 0 movies" under an empty table — a sentence with no information in it, on the one screen where the user most needs to be told plainly that there is nothing. Both the footer and `DataTable`'s `summary_position: :top` line now suppress it, and a footer with neither summary nor controls to draw stops emitting its flex container and vertical padding instead of leaving a gap.

  **`Bali::Pagination::PagyAdapter` is the only file in the gem that touches Pagy.** Pagy keeps `series` — the `[1, :gap, 7, "8", 9, :gap, 36]` list the buttons are built from — `protected`, and stores the request it was built with in an ivar with no reader; `Bali::Pagination::Component` reached for both inline, which is why every Pagy upgrade broke pagination in whatever page happened to render first, with no test in between. The adapter has a contract of its own and 26 tests against it, so a Pagy upgrade now fails a unit test and there is exactly one file to fix. Nothing else in `app/` or `lib/` calls `send(:series)` or `instance_variable_get` on a Pagy.

  **`Pagination` gets `fragment:` and `data:`, and `url:` stops being ignored** (#654). Paging a section halfway down a page jumped the reader to the top, because every link was a plain navigation with no anchor and there was no way to inject one; `fragment: '#results'` now appends it to every link, `data: { turbo_frame: 'movies' }` reaches the `link_to`s so a listing can page inside a Turbo Frame, and both are forwarded by `PaginationFooter` along with the `size:`/`variant:`/`url:` it previously swallowed. `url:` was dead code whenever the Pagy came from the `pagy()` helper — Pagy 43 injects the request unconditionally, and the component took the branch that ignored the parameter — so it now wins outright when given. **That is the breaking half:** if you pass `url:` *and* build your Pagy with `pagy()`, links used to keep the current query string and now do not. Either drop `url:` and let Pagy build the URLs (use `pagy(scope, path:)` / `pagy(scope, fragment:)` for those), or include the query string in the `url:` you pass. The anonymous `**options` bucket on `Pagination::Component.new` is gone; it never reached the template.

  **Honouring `url:` exposed a URL builder that could not spell a countless page,** so that got fixed in the same pass. Countless pagination does not put the page number in the link: it puts `"5+4"`, the page plus the last page Pagy knows about, wrapped in a `Pagy::EscapedValue` so the `+` survives into the query string. Bali built that query with `Rack::Utils`, which escaped it to `5%2B4` and dropped the half Pagy reads back. The code was the same before this release; it was simply unreachable, because the branch that ran it only ever saw a Pagy that had no request and therefore no URL to compare against. The adapter now asks Pagy for both the page value and the query string, and a test asserts the hand-composed URL is byte-for-byte the one Pagy builds from a request.

  **The listing's footer keeps the exact box it had.** Sharing an implementation is not licence to resize anything, and the first cut of this change did: the standalone band pads itself with `py-4`, `DataTable` added `mt-4 pt-4` on top, and the two together left a 16 px bottom padding the inline footer never had — `pt-4` cannot cancel the bottom half of a `py-*`, and Tailwind settles that pair by stylesheet order rather than by the order the classes are written in. The spacing is now a set the caller *swaps* rather than one it layers onto: `PaginationFooter(divider: true)` moves the space above the line and draws the rule, which is what `DataTable` passes, and a characterization test pins the footer's class list against the string the inline version emitted. Measured A/B against `3.0` with the same stylesheet: 57 px at 1280, 93 px at 375, unchanged on both.

  **What did not change:** `with_custom_pagy_nav` on `DataTable` still replaces the controls (it forwards to the footer's new `controls` slot), and `show_summary:`/`summary_position:`/`item_name:` keep their meaning. One thing did: on a phone the footer's summary now sits *above* the controls instead of below, because the inline version carried `order-*` utilities that flipped them and the shared one does not. Same height, same spacing, reversed reading order — one order for both components was the point of collapsing them.

- **The five page components get ONE surface, and it lives in `Bali::PageComponents::Shared`.** Through v2 the concern shared exactly one thing — the actions bar and its `⋯` — and everything else diverged. The inventory, which is what it took to see the problem:

  | | DashboardPage | DocumentPage | FormPage | IndexPage | ShowPage |
  |---|---|---|---|---|---|
  | `back:` | **no** | yes | yes | yes | yes |
  | `max_width:` | 4 keys, default `2xl` | **no** | 5 keys, default `md` | **no** | **no** |
  | `nav` slot | yes | **no** (`subheader`) | **no** | yes | yes |
  | `title_tags` slot | **no** | yes | **no** | **no** | yes |
  | body slot | `body` | **`preview`** | `body` | `body` | `body` |
  | `sidebar` slot | **no** | **no** | yes | **no** | yes |
  | header-to-body gap | none | `mt-6` | `mt-6` | `mt-4` | `mt-6` |
  | subtitle size | `text-sm` | `text-base` | `text-sm` | `text-sm` | `text-base` |

  The two `max_width:` tables did not agree: `:md` did not exist in DashboardPage, `:"2xl"` did not exist in FormPage, and in the other three the argument raised `ArgumentError` — the same symbol meant different widths depending on who you handed it to. There is now **one** six-key table (`sm`/`md`/`lg`/`xl`/`2xl`/`full`) in the concern, and the only thing that still differs per component is the DEFAULT: `:"2xl"` for DashboardPage, `:md` for FormPage, `:full` for the other three. `:full` is a deliberate no-op — `mx-auto max-w-full` on a block `div` moves nothing — so the three that never had a container inherit the option without their layout shifting. Measured in the browser at 390px and 1440px, across all six keys.

  `back:`, `title_tags`, `nav`, `body`, `sidebar` and a shared `render_page_header` move into the concern, so **DashboardPage gains `back:`; FormPage and DocumentPage gain `nav`; DashboardPage, FormPage and IndexPage gain `title_tags`; and all five gain `sidebar`**. The body-plus-sidebar grid that ShowPage and FormPage carried copied verbatim — the same six classes in both files — is now `render_body_with_sidebar` with `sidebar_width:` (`:default` a third, `:narrow` a quarter, `:wide` a half). The only thing FormPage does not share is wrapping the body in a `Card`, and that is a three-line overridden method.

  **What changes in your render when you upgrade.** Three things, all spacing or size, none structural: IndexPage's body goes from `mt-4` to `mt-6`, the gap the other four use; ShowPage and DocumentPage's subtitle goes from `text-base` to `text-sm`, the `SUBTITLE_CLASSES` PageHeader itself declares and the other three already rendered (those two arrived through the `with_subtitle` slot, whose size is derived from the `h6` tag, instead of through the constructor argument); and DashboardPage's stats grid drops its `mb-6` because the body's `mt-6` now makes that gap — a dashboard with no `body` stops trailing 24px of air. The rest of the HTML is identical apart from the class order on the title's `h3` and whitespace, which shifts because the header is assembled from Ruby instead of from five ERB templates.

  **`DocumentPage` renames its `preview` slot to `body`.** It was the only one of the five with a different name for the same thing. `with_preview` keeps rendering and warns through `Bali.deprecator` until 4.0, so a host that misses one gets a warning, not a blank page. The `subheader` slot is untouched: it paints full-bleed, before the panel layout, and is not the same thing as a `nav`.

  **`DashboardPage#with_stat` renders an actual `Bali::StatCard`.** There were two stat cards with two designs in the same repo (three counting `InfoLevel`): DashboardPage's was inline markup with its own colour table. The one that stays is StatCard, so the label becomes uppercase `text-xs`, the figure `text-3xl`, the icon sits in a tinted circle, and `change:` lands in the `footer` slot. This is visible on any dashboard; `with_stat`'s signature does not change. Along the way `StatCard#icon_name` stops being required — `with_stat` always allowed omitting the icon, and a card without one is a card, not an error.

  **The concern's contract is tested once, walking the five.** `test/bali/components/page_components/shared_contract_test.rb` is one test per rule — the shared header, the `nav`'s position, the six `max_width` keys across all five, the three `sidebar_width` values, the `⋯` of secondary actions, the export menu — iterating the component list instead of being copied five times. Copied coverage is exactly what had left ShowPage and DashboardPage without a single test of the v3 `⋯` while IndexPage had six.

  **Constants that move**: `Bali::DashboardPage::Component::MAX_WIDTHS` and `Bali::FormPage::Component::MAX_WIDTHS` are now `Bali::PageComponents::Shared::MAX_WIDTHS`, and `Bali::DashboardPage::Component::STAT_ICON_COLORS` is gone because the palette that rules is `Bali::StatCard::Component::COLORS`. `Bali::DashboardPage::Stat` still exists with the same five members.

  **What this deliberately does NOT touch**: PageHeader's heading hierarchy — it still emits an `h3` and an empty `h6` when there is no subtitle — and its responsive stacking. That is #685.
- **Every overlay reads its z-index from one documented scale, and every old number changes.** Each overlay used to pick its own: dropdown `50`, drawer `60` on the root and `9999` on the panel, modal `61`, command palette `100`/`101`, toast `101`, hovercard `9999`, flatpickr's calendar `99999`, SlimSelect's list `10000`, BlockNote's portaled menus `9999 !important`. Nothing related those numbers to each other, so ordering two overlays was guesswork and the only reliable move was to outbid the largest one you could find — which is literally what happened when identity needed a toast above a modal and wrote `!z-[10001]`. There are now seven tokens in `app/assets/stylesheets/bali/z_index.css`, a hundred apart so a host can slot its own overlay between two of them: `--bali-z-dropdown: 200`, `--bali-z-drawer: 300`, `--bali-z-modal: 400`, `--bali-z-command: 500`, `--bali-z-popover: 600`, `--bali-z-toast: 700`, `--bali-z-tooltip: 800`. The per-component mapping is in [the migration guide](docs/guides/migration-v2-to-v3.md).

  **`--bali-z-popover` is the tier that is not obvious, and it is the one that was load-bearing.** flatpickr's calendar, SlimSelect's list, `Status`' panel and BlockNote's menus all portal themselves to `<body>`, which is exactly why they carried the absurd numbers: a date field inside a modal has to render *above* that modal or the field is unusable. They sit at 600, above `command` and below `toast`, so opening a datepicker from inside a dialog still works and a notification still covers it.

  **What breaks is any host CSS written against the old numbers.** A rule that put something at `z-70` to clear Bali's modal at `61` now sits under every Bali overlay; `!z-[10001]` still wins but no longer needs to. The fix is to read the token instead of a number — `z-[calc(var(--bali-z-toast)_+_1)]` — or to move the whole scale by redeclaring the tokens.

  **The tokens are declared as `:where(:root)` inside `@layer theme` so that a host can actually beat them.** Nothing else in the cascade declares `--bali-z-*`, so this file has nothing to outrank and every reason to be easy to override: `theme` is the first layer Tailwind declares and `:where()` carries zero specificity, so a plain `:root` in the host's `@theme {}` block wins on specificity within the same layer, an unlayered `:root` wins by being unlayered, and a `z-*` utility on the element still beats all of it. Measured in the browser, both ways. This is deliberately *not* where the daisyUI structural fallbacks in `general.css` live — those sit in a later position and cannot be overridden from `@theme {}` at all.

  **App chrome stays out of the scale, below it.** `Navbar`'s sticky bar (50), `SideMenu`'s fixed rail (40) and its mobile scrim (30), and the floating bulk-action bars (40/50) keep their numbers: they are page furniture, and the scale starting at 200 is what guarantees every overlay covers them. Intra-component stacking that never competes with another overlay — a tippy arrow at `z-[1]`, a Gantt resize handle at `z-[2]`, flatpickr's own nav arrows at 3 — is untouched for the same reason.

- **`Bali::HoverCard::Component::DEFAULT_Z_INDEX` is gone**, and `z_index:` now defaults to `nil`. The constant was `9999`; hardcoding the scale's top value in Ruby would have meant a host moving `--bali-z-tooltip` got no change in its hovercards. With no `z_index:` the component emits no `data-hovercard-z-index-value` at all and the controller resolves `--bali-z-tooltip` at connect time; passing `z_index:` explicitly still wins, unchanged. `Bali::Tooltip` gained the same behaviour — it never passed a z-index and was silently taking tippy.js's own `9999` default. Both go through `app/assets/javascripts/bali/utils/z-index.js`, which exists because tippy writes the value as an inline style and an inline style cannot hold a `var()` reference.

- **The five page components get ONE surface, and it lives in `Bali::PageComponents::Shared`.** Through v2 the concern shared exactly one thing — the actions bar and its `⋯` — and everything else diverged. The inventory, which is what it took to see the problem:

  | | DashboardPage | DocumentPage | FormPage | IndexPage | ShowPage |
  |---|---|---|---|---|---|
  | `back:` | **no** | yes | yes | yes | yes |
  | `max_width:` | 4 keys, default `2xl` | **no** | 5 keys, default `md` | **no** | **no** |
  | `nav` slot | yes | **no** (`subheader`) | **no** | yes | yes |
  | `title_tags` slot | **no** | yes | **no** | **no** | yes |
  | body slot | `body` | **`preview`** | `body` | `body` | `body` |
  | `sidebar` slot | **no** | **no** | yes | **no** | yes |
  | header-to-body gap | none | `mt-6` | `mt-6` | `mt-4` | `mt-6` |
  | subtitle size | `text-sm` | `text-base` | `text-sm` | `text-sm` | `text-base` |

  The two `max_width:` tables did not agree: `:md` did not exist in DashboardPage, `:"2xl"` did not exist in FormPage, and in the other three the argument raised `ArgumentError` — the same symbol meant different widths depending on who you handed it to. There is now **one** six-key table (`sm`/`md`/`lg`/`xl`/`2xl`/`full`) in the concern, and the only thing that still differs per component is the DEFAULT: `:"2xl"` for DashboardPage, `:md` for FormPage, `:full` for the other three. `:full` is a deliberate no-op — `mx-auto max-w-full` on a block `div` moves nothing — so the three that never had a container inherit the option without their layout shifting. Measured in the browser at 390px and 1440px, across all six keys.

  `back:`, `title_tags`, `nav`, `body`, `sidebar` and a shared `render_page_header` move into the concern, so **DashboardPage gains `back:`; FormPage and DocumentPage gain `nav`; DashboardPage, FormPage and IndexPage gain `title_tags`; and all five gain `sidebar`**. The body-plus-sidebar grid that ShowPage and FormPage carried copied verbatim — the same six classes in both files — is now `render_body_with_sidebar` with `sidebar_width:` (`:default` a third, `:narrow` a quarter, `:wide` a half). The only thing FormPage does not share is wrapping the body in a `Card`, and that is a three-line overridden method.

  **What changes in your render when you upgrade.** Three things, all spacing or size, none structural: IndexPage's body goes from `mt-4` to `mt-6`, the gap the other four use; ShowPage and DocumentPage's subtitle goes from `text-base` to `text-sm`, the `SUBTITLE_CLASSES` PageHeader itself declares and the other three already rendered (those two arrived through the `with_subtitle` slot, whose size is derived from the `h6` tag, instead of through the constructor argument); and DashboardPage's stats grid drops its `mb-6` because the body's `mt-6` now makes that gap — a dashboard with no `body` stops trailing 24px of air. The rest of the HTML is identical apart from the class order on the title's `h3` and whitespace, which shifts because the header is assembled from Ruby instead of from five ERB templates.

  **`DocumentPage` renames its `preview` slot to `body`.** It was the only one of the five with a different name for the same thing. `with_preview` keeps rendering and warns through `Bali.deprecator` until 4.0, so a host that misses one gets a warning, not a blank page. The `subheader` slot is untouched: it paints full-bleed, before the panel layout, and is not the same thing as a `nav`.

  **`DashboardPage#with_stat` renders an actual `Bali::StatCard`.** There were two stat cards with two designs in the same repo (three counting `InfoLevel`): DashboardPage's was inline markup with its own colour table. The one that stays is StatCard, so the label becomes uppercase `text-xs`, the figure `text-3xl`, the icon sits in a tinted circle, and `change:` lands in the `footer` slot. This is visible on any dashboard; `with_stat`'s signature does not change. Along the way `StatCard#icon_name` stops being required — `with_stat` always allowed omitting the icon, and a card without one is a card, not an error.

  **The concern's contract is tested once, walking the five.** `test/bali/components/page_components/shared_contract_test.rb` is one test per rule — the shared header, the `nav`'s position, the six `max_width` keys across all five, the three `sidebar_width` values, the `⋯` of secondary actions, the export menu — iterating the component list instead of being copied five times. Copied coverage is exactly what had left ShowPage and DashboardPage without a single test of the v3 `⋯` while IndexPage had six.

  **Constants that move**: `Bali::DashboardPage::Component::MAX_WIDTHS` and `Bali::FormPage::Component::MAX_WIDTHS` are now `Bali::PageComponents::Shared::MAX_WIDTHS`, and `Bali::DashboardPage::Component::STAT_ICON_COLORS` is gone because the palette that rules is `Bali::StatCard::Component::COLORS`. `Bali::DashboardPage::Stat` still exists with the same five members.

  **What this deliberately does NOT touch**: PageHeader's heading hierarchy and its responsive stacking, which ship in the same release under their own entry above.

- **Every translation key moves to `bali_view.*`, and host overrides start working.** v2 shipped its strings under three roots — `bali.*`, `view_components.bali.*` and `helpers.*` — two of which belong to somebody else: `view_components` is the namespace `view_component-contrib` reserves for the host and shares with any other component library, and `helpers` is Rails', which resolves the host's own form labels and submit buttons there. A host that wanted to change one Bali string had to guess which of the three it lived in. There is now one root per gem in the family, and this one is `bali_view`. Two rules cover 302 of the 306 keys (`bali.X` → `bali_view.X`, `view_components.bali.X` → `bali_view.X`); the five live `helpers.*` keys move next to the FormBuilder module that emits them, and the full table is in [the migration guide](docs/guides/migration-v2-to-v3.md). Three keys disappear because nothing ever read them and each duplicated a sibling: `view_components.bali.filters.{filters,remove_filters,attributes.date_range.custom}`, plus the dead `helpers.apply.text`.

  **The move is two lines, not 85 edits.** 85 of the call sites use the relative `t('.key')` form, which view_component-contrib resolves as `"#{i18n_namespace}.#{contrib_i18n_scope}"` — so setting `i18n_namespace` on `Bali::ApplicationViewComponent` relocates all of them at once, and dropping the leading `bali` from the class-name-derived half is what keeps them out of `bali_view.bali.*`. Only the 152 call sites with an explicit key were rewritten.

  **`config/locales` is no longer added by hand, and that is the fix.** The engine appended its own locale files to `i18n.load_path` on top of the copy `Rails::Engine` already registers. I18n merges in load order and the last file wins, so the gem's files — appended after the host's — beat the app: **no override of a key Bali defines has ever taken effect** in any version. What looked like a working override was always a key Bali did not define. The initializer is gone; `Rails::Engine` registers `config/locales` with engines before the app, so the host wins. The interaction to watch: an app that "overrode" `view_components.bali.pagination_footer.summary` (a key that only existed as an inline English default) was really adding it — that key now ships in both locales under `bali_view.pagination.summary` (see the pagination entry below, which is where it landed), so the old declaration is silently dead until renamed.

- **44 hardcoded UI strings become translatable.** `DocumentEditor`'s entire app bar (17 strings — the template called `t()` zero times), the `RichTextEditor` bubble menu (19, including a `placeholder="Ingresa la URL"` sitting in an otherwise English file), `BlockEditor`'s disabled notice and export buttons, `DocumentPage`'s panels, and loose `aria-label`s on `Avatar::Upload`, the mobile `Calendar` header, `SimpleFilters`' number-range placeholders, the Filters panel and `Message`. Two `aria-label`s got more specific while being extracted — `Bali::Message`'s close button reads "Close message" and the Filters panel's reads "Close filters" — because a bare "Close" gives a screen reader nothing to tell several dismissible things apart. `RichTextEditor::Component` had to move its `prepend_values` out of `initialize`, where `t` has no view context, into a memoized method that runs at render.

  Not included, and deliberately: the ~40 strings that live inside the editors' `.js`/`.jsx` and are generated by JavaScript rather than the server. #700 rewrites that JS contract and deprecates `RichTextEditor`; translating a contract that is about to break is work thrown away. The inventory is on that issue, line by line.

- **The datepicker stops assuming Spanish.** `DatepickerController`'s `locale` value defaulted to `'es'`, and `setLocale` returned flatpickr's Spanish locale for **every** code that was not `'en'` — so a host on `fr` rendered a Spanish calendar and nothing said so. The default is `'en'` and the locale table is explicit: one entry per locale this gem ships strings for, anything else falling back to flatpickr's built-in English. Static import specifiers on purpose — `import(\`…/${code}.js\`)` would cover all 67 flatpickr locales in one line, but esbuild cannot bundle a computed specifier, and importing `l10n/index.js` to index it drags a 100 kB locale table into every host's bundle to serve locales the gem has no strings for. A host that needs another one calls `flatpickr.localize()`.

- **Version floors move to Rails 8.1 and daisyUI 5.7.** The gemspec asked for `rails >= 7.0` while already requiring `ruby >= 4.0`, a combination no released Rails 7 supports — the floor was decorative, and `installation.md` advertised a third set of numbers ("Ruby 3.0+"). It is now `rails >= 8.1, < 9.0`, which is what all six consuming apps run and what every component is actually tested against; Bundler turns a Rails 7 host into a resolution error instead of a runtime surprise. daisyUI goes 5.6.x → **5.7.9** in the gem and in the dummy app, restoring the repo's own rule that dependencies are current before substantial work starts — the component CSS is written against the 5.7 class set, and daisyUI is the host's npm dependency, so nothing enforces it for you.

- **`Bali.deprecator`** — one `ActiveSupport::Deprecation` for the whole gem, registered as `Rails.application.deprecators[:bali]` so a host silences, logs or raises Bali's warnings with the `config.active_support.deprecation` it already sets for Rails' own, and can single Bali out (`config.active_support.deprecators[:bali].behavior = :raise`) or scope an exception (`Bali.deprecator.silence { }`). Registration runs `before: :load_environment_config`, mirroring Rails' own `active_support.deprecator` initializer: `active_support.deprecation_behavior` applies the configured behavior to whatever is registered by then, and a plain engine initializer runs after it — registering there would have produced a deprecator that ignored the app's configuration. v3-era deprecations go through it; ad-hoc `warn` calls do not.

- **`Bali::Table` drops its second selection system.** v2 carried two complete, mutually exclusive ways to select rows in the same component. The legacy one took `bulk_actions:` — an array of `{ name:, href:, method: }` hashes — and rendered its own checkbox column, its own fixed bottom bar and its own `Bali::Table::BulkAction::Component` buttons, all driven by a `table` Stimulus controller. The v3 one is `selectable: true` wired to a `bulk-actions` controller on an ancestor. Declaring both already raised, the constructor said in so many words that they were exclusive, and the previews shipped one scenario for each. Only `selectable:` survives: `bulk_actions:`, `Bali::Table::BulkAction::Component`, `TableController` and the floating bar in the template are all deleted. Verified beforehand — zero call sites of `bulk_actions:` across the six consuming apps, which is what made the removal cheap enough to do in one pass.

  **The replacement for the standalone case is `Bali::BulkActions(variant: :floating)`** — the same fixed bottom bar with a counter and action buttons, but as a component that wraps the table instead of an option inside it. Inside a `DataTable` nothing changes: `with_bulk_actions` already put the controller on the container and rendered the `:toolbar` variant. Per action, `name:` becomes `label:` and `variant:`/`size:` are available; `method:` behaves exactly as before, including the `:get` case that renders a link whose href the controller rewrites with `?selected_ids=[...]`. The `selected_ids` JSON payload is unchanged, so server-side controllers keep working untouched.

  **`data-controller="table"` disappears from every table container, including tables that never used bulk actions.** Bali emitted it unconditionally from `Bali::Table`, so the attribute rode on every table the gem has ever rendered while doing nothing for the overwhelming majority of them. Two consequences for a host: a Stimulus controller of your own registered under the identifier `table` was being attached to Bali's markup for free and now is not, and `TableController` is no longer exported from the npm package nor registered by `registerAll` (63 controllers instead of 64), so an import of it fails at build time rather than silently resolving to `undefined`.

  **Both removed keywords raise `ArgumentError` naming the replacement.** `Bali::Table` funnels unknown keywords into the generic HTML-attribute hash, so without an explicit guard a leftover `bulk_actions:` would have rendered `<table bulk-actions="...">` — a table that looks correct, has no checkbox column, no action bar and no error anywhere. The same guard covers `Bali::Table::Row(bulk_actions:)`, which was internal wiring but would have leaked into the `<tr>` the same way. The step-by-step rewrite is in [the migration guide](docs/guides/migration-v2-to-v3.md).
- **`Bali::Icon::DefaultIcons` is gone — 1,580 lines and 166 inline SVGs of compatibility that had stopped serving anyone.** It was the fifth and last step of the icon resolution pipeline, the one labelled "full backwards compatibility". Measured against the 167 names it could serve: **137 were already intercepted by the Lucide name map and 28 by `KeptIcons`**, both of which sit *earlier* in the pipeline — so for 165 of them the fallback had been unreachable code since the Lucide migration, and deleting it changes nothing you can see. **Two** names were still being served by it and lose their glyph: `money-bill-wave` (use `banknote`, or `hand-coins` if the point was payment rather than cash) and `question-circle` (use `circle-help`). The second one is worth a grep: the Lucide map *does* carry an entry for that icon, but under the key `question_circle` — the single underscored key in the whole table, a leftover from the v1 hash — so the underscored spelling keeps working and the one that matches every other name in the library does not.

  **The larger surface is elsewhere, and grepping for those two names will not find it.** The deleted step did not look a name up as written: it upcased it and turned dashes into underscores to build a constant name, so `arrow_left`, `ARROW-LEFT` and `Arrow_Left` all resolved to the same SVG as `arrow-left`. The three surviving steps match **exactly** — lowercase, dashes, as written. In practice that means the snake_case spelling of every multi-word icon now raises: **73 names**, listed one by one in [the migration guide](docs/guides/migration-v2-to-v3.md), and for 72 of them the fix is to write the dashed name. `money_bill_wave` is the one with no dashed equivalent to fall back on.

  `IconNotAvailable` closes the gap. It already suggested near names, but compared them literally, so `arrow_left` matched nothing and the message degraded to a link to lucide.dev. Matching now ignores the difference between dashes and underscores: `arrow_left` answers `Did you mean: arrow-left?`.

  **`Bali::Icon::Options` narrows to match.** `Options.icons` used to be the 166 legacy SVGs merged with `Bali.custom_icons`; it is now the 28 kept icons merged with `Bali.custom_icons` — the icons Bali ships as literal markup. A Lucide-backed name has no SVG of its own until lucide-rails renders one at a size, so `Options.find('user')` raises `IconNotAvailable` where it used to return the old FontAwesome glyph; `Options` was never the rendering path, `Bali::Icon::Component` is. The 28 kept SVGs move out of Ruby into `app/components/bali/icon/svg/<name>.svg`, one file per name and byte-for-byte the same markup: `kept_icons.rb` stays a readable registry instead of becoming a 570-line blob, the SVGs are openable by whoever draws them, and the gemspec's `app/**/*` glob already ships them.

- **`Bali::GanttChart` is gone — the component, its nine sub-components, its two Stimulus controllers and the `./gantt` npm entry point.** No app in the group renders it: afal-apps adopted it in its PR #203 and replaced it with a React island in #206, and the only live call sites left were this repo's own dummy app and previews. Keeping it meant carrying a drag/resize/dependency-canvas engine, a `sortablejs` entry point and 21 tests for a surface with no consumer, so it goes out with the rest of the v3 dead weight rather than being repaired.

  **This also closes #667 as "won't fix in v3", not as "fixed".** That issue asked for a per-task `colors:` so a portfolio Gantt could encode project status in the bar colour — the component hardcoded one palette for the whole chart, and `cell:` was no escape because the background lives on a child div with an inline `style`. The API it proposed is right and it is not being shipped here: the colour-by-row reading arrives in v3.1 with a new `Bali::Gantt` and a `color_by:` parameter, designed around read-only portfolio views instead of retrofitted onto an editor. A host that needs it before then should keep whatever it is doing now — the issue records the workaround (a per-status class with `!important`) and why the component was the wrong tool anyway (the `zoom: :month` duration is computed as `days / 30`, and the bar colours derive from daisyUI v3 aliases `--in` and `--b3` that no v5 theme defines).

  **A host that imported `bali-view-components/gantt` gets a resolution error, which is the point** — the export is removed from `package.json` rather than left as a stub, so a bundler fails at build time instead of an app rendering an empty div at runtime. `sortablejs` stays in the optional peer list: Kanban and SortableList still use it. `GanttChartController` and `GanttFoldableItemController` leave the controller manifest's optional-entry allowlist, and `bali_view.gantt_chart.*` leaves both locale files.

- **The canonical DataTable's third display mode is a `Bali::Calendar`, and its value in `?view=` is `calendar`, not `timeline`.** The Gantt was the surface behind that mode in the reference composition (`bali/data_table/complete`, `bali/index_page/complete` and `/admin/movies` + `/movies` in the dummy), so deleting the component without replacing the mode would have left the reference page with a view switch whose third button rendered nothing. **This is a change to Bali's own previews and dummy app, not to any API** — the DataTable still ships no display modes, and `with_view(value:)` still takes whatever symbol a host wants. A host that declared a `:timeline` view of its own is untouched.

  The Calendar was picked over the obvious name-match, `Bali::Timeline`: the mode existed to answer *when*, which is what a calendar answers and a vertical event list does not, and it consumes the same two columns (`production_starts_on` / `production_ends_on`) the dummy migration added for the Gantt, so the preview keeps painting real records instead of a decorative stub. It also teaches the half of `with_content` the Gantt could not: a Gantt asked the slot for a surface *and* the horizontal scroll wrapper, a Calendar brings both of its own and asks for `surface: false` — two modes with opposite needs is what makes it obvious why the generic slot takes the two knobs separately and `with_table`/`with_grid` are only sugar over them. The Calendar header goes in without `route_path:`, so it renders the month label and no prev/next: month navigation would put a second query string on a URL the filters, the sorting and the view switch already own.

- **`Bali::Clipboard::SucessContent` is gone.** It was a constant alias kept alive for the misspelling of `SuccessContent`. Zero usages across the six apps.

- **`Bali::Utils::Url#add_query_params` is gone**, and `#add_query_param` (singular, the only form anything called) absorbed its body with the bug fixed. `Rack::Utils.parse_query` returns String keys, so merging a Symbol name left BOTH entries in the hash and `to_query` emitted the param twice — `?view=grid&view=table` — which Rack resolves last-wins, handing the value back to whatever was already in the URL. That is **#653**: TDFlow's grid/table toggle was stuck on table because the mode it was leaving won the merge. The name is normalized to a String before merging, so setting a param that is already present now replaces it. Multi-value names (`[]`, `_in`, `_not_in`) still keep every value; every other repeated param still collapses to the first.

- **The npm package stops shipping the repository, and starts declaring what it needs.** `package.json` had no `files` key, so `npm publish` would have shipped everything not gitignored: **1,437 files**, including the whole `spec/` tree (the dummy Rails app with its fixtures and seeds), `test/`, `docs/`, `cypress/`, `.github/`, `.claude/`, `bin/` and `scripts/`. A whitelist of `app/**/*`, `lib/bali/**/*.rb`, `MIT-LICENSE` and `README.md` cuts that to **930 files, 2.1 MB unpacked, a 547 kB tarball**. The `.rb` and `.erb` files under `app/` stay on purpose and must not be pruned further: the install guide has Tailwind scan them with `@source` *inside* `node_modules`, so dropping them would silently strip every class name Bali emits from Ruby out of the host's compiled CSS — components would render with correct markup and no styling, and nothing would report an error.

  **`daisyui` moves from `dependencies` to `peerDependencies`, and that is the break.** It was the package's only runtime dependency, so every host received it transitively, pinned to whatever range Bali picked. It belongs to the host: the host is what configures daisyUI themes, and two copies at different versions is a class-set mismatch with no good error message. **A host that never installed daisyUI explicitly now has to** — Yarn Classic does not install peer dependencies at all, and while npm 7+ auto-installs required peers, it will now surface a version conflict instead of quietly nesting a second copy.

  **The rest of the peer list previously existed only as an ellipsis in a code comment.** `@hotwired/stimulus` went undeclared while 69 shipped files imported it, and `@hotwired/turbo-rails` is reached through the `window.Turbo` global rather than an import, so no bundler could ever have told a host it was missing — those two join `daisyui` as the three required peers. The other 62 are marked `optional` through `peerDependenciesMeta` and grouped, in the `//peerDependencies` comment block, under the entry point that reaches for each one; every one of them sits behind a dynamic `import()`, so an app that renders no carousel owes nothing for `@glidejs/glide`. Still deliberately absent: the four `@blocknote/xl-*` packages and their companions, which are `GPL-3.0 OR PROPRIETARY` and were being installed by reflex whenever they were declared.

- **`Bali::Timeline` renders each entry once, and its slots lose the `tag_` prefix.** Every item used to emit its heading and its content **twice** — once inside `.timeline-start`, once inside `.timeline-end` — and hide one copy with CSS. The cost was not cosmetic: any `id` a host put in an item's block existed twice in the document, two `turbo-frame`s ended up sharing one id (the second wins, so a stream update landed in the invisible copy and nothing appeared to happen), and every nested ViewComponent ran twice, database queries included. The side is now decided in Ruby before rendering (`Timeline::Component#next_item_side`), so an item emits exactly one content box: `position: :left` puts it on the start side, `:right` on the end side, and `:center` alternates. `app/components/bali/timeline/index.css` drops from 45 lines to the two `text-align` rules the alternating layout still needs — a host whose CSS targeted `.timeline-content-box.timeline-end` on a left-aligned timeline was targeting the hidden copy, and now matches nothing.

  **`with_tag_item` → `with_item`, `with_tag_header` → `with_header`.** The old names came from an internal slot collection called `tags`, which was never a timeline concept; the collection is now `entries`, so a host reading `c.tags` in a template reads `c.entries`. Both old setters survive as shims that warn through `Bali.deprecator` and are removed in v4, so an app that updates without touching its views keeps working and is told where to look.

  **`:center` alternates by item, which changes what centred timelines look like.** The old alternation was `li:nth-child(odd)` in CSS, and a header is an `li` too — so a header between two items flipped the parity and put two consecutive items on the same side. Bali's own `bali/timeline/default` preview showed it: with three headers among four items, events 2 and 3 both landed on the left. Alternation now counts items only. A centred timeline with no headers renders identically; one with headers moves some boxes to the other side, which is the fix rather than a regression.

  **`Timeline::Header`'s `tag_class:` is deprecated, and its other options stop being swallowed.** `tag_class:` replaced the badge colour outright, and existed to reach class combinations `color:` cannot express, such as `badge-outline badge-primary`. It warns through `Bali.deprecator` and goes away in v4; pass `color: :primary, class: 'badge-outline'` instead. That works because `**options` now actually reach the badge — the component accepted them and rendered none of them, so every `class:`, `data:` and `aria-*` passed to a timeline header has been silently dropped since the DaisyUI migration.

  Not included, deliberately: the compact layout and the item state variants tracked for v3.1. Deciding the side in Ruby is the groundwork those need; adding them here would have widened a correctness fix into a feature.
- **`Reveal`'s trigger is a `<button>`, and `TreeView` stops claiming to be a tree.** Both were `<div>`s with a click handler: unreachable by keyboard, unannounced by a screen reader, and — in `TreeView`'s case — carrying `role="tree"`/`role="treeitem"`/`role="group"`, which promises roving tabindex, arrow-key movement and type-ahead that the component has never implemented. A tree a screen-reader user cannot operate with arrow keys is worse than no role at all, so the roles are gone and the DOM says what the thing actually is: `TreeView` renders `<ul>`/`<li>`, each expandable branch gets a real `<button class="caret">` with `aria-expanded` and `aria-controls` pointing at the `<ul class="children">` it discloses, and childless items get an inert `<span aria-hidden="true">` spacer where the button would be (an invisible button is still a tab stop). `Reveal`'s trigger gains `type="button"`, `aria-expanded` and an `aria-controls` pointing at the content, which now carries an `id` — derived from the component's own `id:` when you pass one, random otherwise. Every class name is unchanged, so CSS keyed on `.tree-view-component`, `.tree-view-item-component`, `.item`, `.children`, `.caret` or `.reveal-trigger` still applies; selectors and test helpers that name the *element* (`div.reveal-trigger`, `[role="treeitem"]`, `span.caret`) do not. Tailwind's preflight already strips a button back to its container's typography, so nothing needed restyling beyond `w-full text-left` on the reveal trigger, which a `<div>` got for free. The full list is in [the migration guide](docs/guides/migration-v2-to-v3.md).

  **`<details>`/`<summary>` was considered for `Reveal` and rejected.** It would hand over keyboard and AT behaviour for free, but `Reveal` is not only a disclosure widget: its controller also toggles a `hidden` class on arbitrary `item` targets that may sit anywhere inside the controller element, which `<details>` cannot reach, and `show`/`hide` are part of its public API for hosts driving it from elsewhere on the page — something `<details>` only exposes through its `open` property, i.e. through the same JavaScript we would be claiming to remove. It would also break every host styling `.reveal-content`, for a component whose animation is a CSS chevron rotation keyed on `.is-revealed`. The accessibility gap was in the trigger, and a `<button>` closes it.

- **`Bali::Tag` drops the Bulma names, and an unknown value now raises instead of rendering nothing.** `COLORS` and `SIZES` carried a block of aliases from the Bulma era — `danger`, `link`, `black`, `dark`, `light`, `white`, `small`, `medium`, `large`, `normal` — under a comment reading "deprecated, remove in v2.0". They outlived that note by two majors because nothing made them cost anything: `COLORS[@color]` returned `nil` for a name it did not know and `class_names` dropped it, so a call site that never migrated rendered an *uncoloured* tag and looked merely unstyled rather than broken. The maps now hold the daisyUI names only, and a value in neither map raises `ArgumentError` at construction. The message is the deliverable as much as the deletion: a removed Bulma name gets its replacement by name (`Bali::Tag::Component: color :danger is a Bulma name removed in v3. Use color: :error.`), anything else gets the list of valid values. The old→new table is in [the migration guide](docs/guides/migration-v2-to-v3.md), together with the `grep` that finds the call sites. Verified beforehand: zero uses of the legacy names across the six consuming apps, so this is hygiene, not a migration.

  **`light:` is rejected rather than simply removed.** It had been deprecated since the daisyUI port, warning through `Rails.logger.warn` — which no one reads — and `style: :outline` has replaced it for two versions. Dropping it from the signature would not have been enough: `**options` becomes HTML attributes, so `light: true` would have rendered `<div light="true" class="badge">`, silently, which is the exact failure mode being removed. The constructor checks `options.key?(:light)` and raises with the replacement named.

  **Validation was added where values were removed, and nowhere else.** `style:` still resolves through a plain hash lookup and still ignores a typo, because nothing was ever taken out of `STYLES` — no call site can have been silently broken by this release. `Bali::Icon` and `Bali::Message` keep their own `:small` / `:danger` scales; only `Tag` changed. One knock-on outside `Tag`: `Bali::Kanban::Column` passes `color:` straight through to a Tag while its own `badge_class` falls back to `:ghost`, so a column declared with a colour outside `Bali::Tag::COLORS` used to render ghost-coloured and now raises.

- **A `Bali::Tag` no longer wraps, which fixes #655 and moves the failure somewhere visible.** daisyUI 5 builds `.badge` as an `inline-flex` box with a fixed `height: var(--size)`, `width: fit-content` and no white-space control: it is single-line by design, and nothing says so. When a container squeezes a Tag below the width its text needs, the text wraps and the pill does not grow — the extra lines render outside it. Measured in the browser at a 1280px viewport before the change, "Regional Operations Supervisor" in a 144px column produced 3 line boxes (`scrollHeight` 43px) inside a 24px pill; in a squeezed `badge-sm` table cell, 2 line boxes (27px) inside a 20px pill. That is the reported symptom that role names "disappeared" from a table. The component now sets `white-space: nowrap`, and every one of those cases measures a single line box with `scrollHeight == clientHeight`. The line-height is pinned at `1.2` for the same reason the height is fixed: inheriting 1.5 puts a `badge-xs` line box at 15px inside a 14px content box, so even one line sat outside its own pill. 1.2 fits every size (xs 12/14, sm 14.4/18, md 16.8/22, lg 19.2/26, xl 21.6/30) and matches `.status-pill`, which solved this for `Bali::Status` already.

  **The trade is real and a host will see it.** A tag that used to wrap now keeps its full width, so the pressure moves from the pill to the container. Inside `Bali::Table` — or anything else with `overflow-x-auto` — the table widens and the container scrolls, which is the fix as #655 proposed it. Inside a fixed-width box with no horizontal scroll the pill now overhangs instead of breaking: measured at 9px on a 256px card holding a 28-character tag. The 31 Lookbook previews that render a Tag and 19 dummy-app pages were then measured at 1280px and 390px, 465 tags in all, each page with and without the rule: no tag ends up clipped by an `overflow-x: hidden` ancestor, none overhangs a container with no scroll to absorb it, and no page gains horizontal scroll it did not already have (`/showcase` overflows by 267px at 390px either way — that is someone else's bug). What the sweep did find is the defect: `bali/table/selectable` rendered three broken pills at 390px and now renders none. The overhang is the honest version of what breaking the pill used to hide.

  **The rule ships in `@layer components`, and that is what makes the escape hatch work.** `.badge` is emitted inside daisyUI's `@layer utilities`, but it declares neither `white-space` nor `line-height`, so nothing there is being fought and the weaker layer is the right one: a host that wants the old behaviour at one call site writes `class: "whitespace-normal"` and the plain utility wins, with no `!` variant. The same rule written unlayered would have beaten that utility and left `whitespace-normal!` as the only way out. A new Lookbook scenario, `bali/tag/long_text`, renders the squeezed containers and the opt-out side by side so the trade is inspectable rather than described.

  Deliberately not done: no `wrap:` keyword, since the opt-out is a class a host can already pass and the component does not need a second way to spell it; and no `max-width: 100%` with an ellipsis, which is the other obvious answer to an overhanging pill but needs an inner element to hang `text-overflow` on — `text-overflow` does not apply to a flex container's anonymous text item, which is why `Bali::Status` puts it on `.status-pill__label`. That is a markup change with its own blast radius and belongs in its own issue. `Bali::Timeline::Header` is untouched: it emits `.badge` markup directly instead of rendering a `Tag`, so it neither gains the nowrap nor risks the overhang.
- **One `color:` for the whole library, and `Bali::Heatmap` starts following the theme.** Seven sibling components each carried a private colour map, and they disagreed about which names existed and about what a name meant. `Bali::Tag` and `Bali::Kanban::Column` kept two separate `badge-*` tables where the second answered `:ghost` to anything it did not recognise; `Bali::Timeline::Item` called its no-colour value `:default` while `Bali::Timeline::Header` also listed `:outline`, which is a style rather than a colour; `Bali::StatCard` had no neutral at all and fell back to `:primary` for a typo; `Bali::Status` took a hex in the same keyword as a palette name; and `Bali::Utils::ColorPicker` held three more lists of its own, two of which nothing read. The visible consequence was `Bali::Heatmap`, whose "DaisyUI colour presets" were **hardcoded hex** — its `:primary` was `#6366f1` no matter what theme the host had chosen — one component away from `Bali::Chart`, which resolved the same names to `var(--color-*)`.

  There is one contract now, `Bali::Color`, and all seven go through it: `color:` takes `:neutral :primary :secondary :accent :info :success :warning :error :ghost` and follows the DaisyUI theme, `custom_color:` takes a hex and deliberately does not. A value outside the list raises `ArgumentError` at construction naming the component and the valid values, and a removed Bulma name is told its replacement by name — the same messages `Bali::Tag` got in #689, now shared. The test that holds this together walks the seven components rather than asserting the same thing seven times.

  **The colour *classes* stay in each component, and that is deliberate**: Tailwind only emits a class it can find as a literal string in a source file, so a shared `"badge-#{name}"` helper would have quietly stripped `badge-neutral` and friends out of the compiled CSS. What is shared is the name list, the validation and the CSS-value resolution; what stays local is each component's literal `badge-*` / `text-*` / `bg-*` table, whose keys a test now pins to `Bali::Color::NAMES`.

  **Heatmap is a declared visual break.** Its ramp is built from `var(--color-*)` now, so a host that picked `:primary` expecting indigo gets its own primary. Measured on `bali/heatmap/color_presets` with the nine ramps side by side: switching from `light` to the `costa-norte` theme changes 6 of 9, `:primary` going from `oklch(0.45 0.24 277.023)` (indigo) to `oklch(0.388 0.066 197.73)` (teal) and `:secondary` from pink to gold. Under `light` → `dark` 2 of 9 change, which is not the change being small — it is that DaisyUI's light and dark share those seven values. The alpha ramp itself is unchanged at 0%…90% in ten steps, but it is now emitted as `color-mix(in oklch, …)`: the old `oklch(var(--color-primary) / 0.5)` form is not valid CSS at all, because DaisyUI 5 stores a complete `oklch(…)` in the variable, and the old hex form produced a 7-character `#6366f10` for the first stop that browsers simply dropped.

  **`Bali::Status` stops hardcoding the light theme.** Its panel was `background-color: #fff` with `#6b7280` text and `#d1d5db` dashed borders, so in any dark theme it opened as a white rectangle over a dark page. Those four declarations read `--color-base-100` / `--color-base-content` now: measured in `dark`, the panel goes from `rgb(255,255,255)` to `oklch(0.2533 0.016 252.42)` with `oklch(0.978 0.029 256.847)` text. Two `!important`s went with them — the component only writes an inline style when something *is* selected, so those rules never had anything to outrank, and inside `@layer components` an `!important` is nearly unbeatable from a host, which is the opposite of what a default wants. The twelve fixed status colours (`:slate`, `:green`, …) stay non-theme on purpose: a workflow's "blue" is not the app's `primary`, and a rebrand should not change what "validated" looks like. They are joined by the semantic names, so `color: :success` means the same thing on a Status as on a Tag.

  **What breaks for a host upgrading**, beyond the heatmap repaint: `Bali::StatCard(icon_name:)` becomes `icon:` (the old spelling warns through `Bali.deprecator` and is removed in v4 — it had to stay in the signature rather than be deleted, or `**options` would have rendered `icon_name="users"` on the card with no icon and no error); `Bali::Timeline::Item(color: :default)` becomes `:ghost`; `Bali::Timeline::Header(color: :outline)` becomes `color: :primary, class: 'badge-outline'`; a hex in `Bali::Heatmap(color:)` or in a `Bali::Status` option's `color:` moves to `custom_color:`; and an unknown name that used to fall back silently now raises in `Heatmap`, `StatCard` and `Kanban::Column`. `Bali::Chart` gains `color:`/`custom_color:` and loses nothing — a chart with neither renders exactly as before, verified in the browser. Removed constants: `Bali::Heatmap::Component::COLOR_PRESETS`, `Bali::Kanban::Column::Component::BADGE_COLORS`, and `ColorPicker`'s `THEME_COLORS`, `CSS_VAR_MAP`, `FALLBACK_COLORS`, `.gradient`, `.theme_color` and `.theme_color_with_alpha`. The full table is in [the migration guide](docs/guides/migration-v2-to-v3.md).

  **`Bali::Chart`'s `color:` needed a JavaScript half, and that is worth knowing before adding one.** `ChartController` recomputes every theme colour in the browser, because a `<canvas>` cannot resolve a `var()` — so a rotation applied only in Ruby was silently undone on connect and dataset 0 came back `--color-primary`. The controller takes the chosen variable as a Stimulus value and rotates its own palette to match; verified live, `color: :success` puts `oklch(76% .177 163.223)` on the first dataset and warning on the second. For the same reason a hex `custom_color:` takes the *whole* palette off the theme rather than just its first entry: mixing one hex with six `var()` strings in one dataset would have rendered the theme half as nothing.

  **Not done, deliberately.** `icon_name:` on `Bali::Link`, `Bali::Button` and `Bali::ImageField::Input` is untouched — the issue named `StatCard`, and those three are a different keyword with a much wider blast radius; it is filed on #691 for its own pass. `ColorPicker#next_color` still resets one entry early, so the seventh theme colour is unreachable for a chart with seven or more series; it is a pre-existing off-by-one, fixing it would change the colours of existing charts, and it is filed rather than smuggled in here.

- **`Bali::Timeline` renders each entry once, and its slots lose the `tag_` prefix.** Every item used to emit its heading and its content **twice** — once inside `.timeline-start`, once inside `.timeline-end` — and hide one copy with CSS. The cost was not cosmetic: any `id` a host put in an item's block existed twice in the document, two `turbo-frame`s ended up sharing one id (the second wins, so a stream update landed in the invisible copy and nothing appeared to happen), and every nested ViewComponent ran twice, database queries included. The side is now decided in Ruby before rendering (`Timeline::Component#next_item_side`), so an item emits exactly one content box: `position: :left` puts it on the start side, `:right` on the end side, and `:center` alternates. `app/components/bali/timeline/index.css` drops from 45 lines to the two `text-align` rules the alternating layout still needs — a host whose CSS targeted `.timeline-content-box.timeline-end` on a left-aligned timeline was targeting the hidden copy, and now matches nothing.

  **`with_tag_item` → `with_item`, `with_tag_header` → `with_header`.** The old names came from an internal slot collection called `tags`, which was never a timeline concept; the collection is now `entries`, so a host reading `c.tags` in a template reads `c.entries`. Both old setters survive as shims that warn through `Bali.deprecator` and are removed in v4, so an app that updates without touching its views keeps working and is told where to look.

  **`:center` alternates by item, which changes what centred timelines look like.** The old alternation was `li:nth-child(odd)` in CSS, and a header is an `li` too — so a header between two items flipped the parity and put two consecutive items on the same side. Bali's own `bali/timeline/default` preview showed it: with three headers among four items, events 2 and 3 both landed on the left. Alternation now counts items only. A centred timeline with no headers renders identically; one with headers moves some boxes to the other side, which is the fix rather than a regression.

  **`Timeline::Header`'s `tag_class:` is deprecated, and its other options stop being swallowed.** `tag_class:` replaced the badge colour outright, and existed to reach class combinations `color:` cannot express, such as `badge-outline badge-primary`. It warns through `Bali.deprecator` and goes away in v4; pass `color: :primary, class: 'badge-outline'` instead. That works because `**options` now actually reach the badge — the component accepted them and rendered none of them, so every `class:`, `data:` and `aria-*` passed to a timeline header has been silently dropped since the DaisyUI migration.

  Not included, deliberately: the compact layout and the item state variants tracked for v3.1. Deciding the side in Ruby is the groundwork those need; adding them here would have widened a correctness fix into a feature.
- **`Reveal`'s trigger is a `<button>`, and `TreeView` stops claiming to be a tree.** Both were `<div>`s with a click handler: unreachable by keyboard, unannounced by a screen reader, and — in `TreeView`'s case — carrying `role="tree"`/`role="treeitem"`/`role="group"`, which promises roving tabindex, arrow-key movement and type-ahead that the component has never implemented. A tree a screen-reader user cannot operate with arrow keys is worse than no role at all, so the roles are gone and the DOM says what the thing actually is: `TreeView` renders `<ul>`/`<li>`, each expandable branch gets a real `<button class="caret">` with `aria-expanded` and `aria-controls` pointing at the `<ul class="children">` it discloses, and childless items get an inert `<span aria-hidden="true">` spacer where the button would be (an invisible button is still a tab stop). `Reveal`'s trigger gains `type="button"`, `aria-expanded` and an `aria-controls` pointing at the content, which now carries an `id` — derived from the component's own `id:` when you pass one, random otherwise. Every class name is unchanged, so CSS keyed on `.tree-view-component`, `.tree-view-item-component`, `.item`, `.children`, `.caret` or `.reveal-trigger` still applies; selectors and test helpers that name the *element* (`div.reveal-trigger`, `[role="treeitem"]`, `span.caret`) do not. Tailwind's preflight already strips a button back to its container's typography, so nothing needed restyling beyond `w-full text-left` on the reveal trigger, which a `<div>` got for free. The full list is in [the migration guide](docs/guides/migration-v2-to-v3.md).

  **`<details>`/`<summary>` was considered for `Reveal` and rejected.** It would hand over keyboard and AT behaviour for free, but `Reveal` is not only a disclosure widget: its controller also toggles a `hidden` class on arbitrary `item` targets that may sit anywhere inside the controller element, which `<details>` cannot reach, and `show`/`hide` are part of its public API for hosts driving it from elsewhere on the page — something `<details>` only exposes through its `open` property, i.e. through the same JavaScript we would be claiming to remove. It would also break every host styling `.reveal-content`, for a component whose animation is a CSS chevron rotation keyed on `.is-revealed`. The accessibility gap was in the trigger, and a `<button>` closes it.
- **Six components that showed information no screen reader could reach.** Each is a different way of saying the same thing on screen and nothing at all to the accessibility tree, and every claim below was read off the browser's own tree (`Accessibility.getFullAXTree` over CDP), not off the markup — an `aria-label` on the wrong element looks right in the HTML and never arrives.

  **`BooleanIcon` had no accessible name, and `nil` lied** (#753). It rendered one Lucide SVG and nothing else; Lucide ships its icons `aria-hidden`, so the node was anonymous and a table cell containing one announced as empty. Colour was the only remaining difference between true and false, which is also WCAG 1.4.1. Every state now renders an `sr-only` name beside the icon — "Yes" / "No" / "Not specified", in `bali_view.boolean_icon.*` — and the wrapper carries `aria-hidden="true"` so the icon is not a second, nameless node. **The value is ternary now.** `nil` used to collapse into `false` through `!!value` and announce "No", which states something the record does not say; it renders a neutral dash in `text-base-content/40` instead. If a host relied on `value: nil` painting a red ✗ — a column of nullable booleans where "not set" was meant to read as "no" — pass `value: false` explicitly. Everything else keeps the old coercion: a truthy non-boolean is still true. A new `label:` gives the cell a real name where the generic one is useless: "Yes" on its own says nothing about *what* is true.

  **`LabelValue` rendered a `<label>` with no control.** A label pointing at nothing is a label for nothing — the text and the value beside it were two unrelated nodes in the tree. It is now a single-pair `<dl>` with `<dt>`/`<dd>`, which reads as term and definition with no ARIA at all (confirmed in the tree as `DescriptionList` → `term "Name"` → `definition "Juan Perez"`). **The outer element changed from `<div>` to `<dl>` and the inner ones from `<label>`/`<div>` to `<dt>`/`<dd>`**, so a selector or test naming those elements — `div.mb-2`, `label.font-bold`, `.min-h-6` as a `div` — stops matching; the class names are all unchanged. Use `Bali::PropertiesTable` instead when the pairs form one set read top to bottom: it is a single `<table>` of `<th scope="row">` rows, so a screen reader gets table navigation over the whole set, where a run of LabelValues is a run of separate one-pair lists.

  **`Tabs` claimed to be a tab widget when it was navigation.** With `href:` on every tab the click leaves the page: there is no panel, so `role="tab"` promised an `aria-controls` target that does not exist and `aria-selected` described state the component does not own. When *every* trigger has an `href:`, it now renders `<nav aria-label>` with plain links and `aria-current="page"` on the active one — verified in the tree as `navigation "Section navigation"` with `link` children and zero `tab` nodes — and the `tabs` Stimulus controller is not attached, because there is nothing for it to switch. A new `label:` names the nav; two of them on one page need telling apart, and `bali_view.tabs.navigation` is the default. **Mixing the two now raises `ArgumentError` instead of rendering.** Half links leaving the page and half tabs owning a panel, inside one `role="tablist"` where every child claims to be a tab, is a combination ARIA does not describe; it used to render in silence. The message names the two ways out: give every tab an `href:`, or drop it from all of them and use `src:` for a panel that loads on demand. Tabs with panels are untouched — same `role="tablist"`/`tab`/`tabpanel`, same controller, same markup.

  **`Chart` was an unnamed canvas.** Everything Chart.js paints is pixels, and the fallback content inside the tag only surfaces when canvas itself is unsupported, so the accessibility tree had an anonymous node where the chart is. The canvas is now `role="img"` with a name: `aria_label:` if given, else the `title:`, else a translated generic (`bali_view.chart.default_label`) — an unnamed `role="img"` is announced as nothing, so a generic name beats none. A name is still not a number, which is what the new `data_table` slot is for: pass a real `<table>` and it renders `sr-only` beside the canvas, and it is the only way a screen reader user reads a value off the chart. `Bali::Chart::Preview#with_data_table` is the worked example.

  **`Heatmap` was a grid of empty cells.** The value lived only in a hover card, so keyboard and screen-reader users had no path to any number, and the axis labels were `<td>`s that associated with nothing. The x labels stay at the foot of the chart, where they always were, but are `<th scope="col">` now — a column header associates with its column wherever in the table it is written — the y labels are `<th scope="row">`, and each cell carries its value as `sr-only` text. Both axes therefore reach the cell as headers and the cell only owes the number. The spacer cells in the header row became `<td>` so every column has exactly one header; the corner cell stays a `<th>` because it names the y-label column. The axis labels pick up `font-normal` to keep the weight the `<td>` had — the visual result is identical, which was the constraint.

  **`Kanban` announced nothing when a card was dropped.** A drop moves the DOM and nothing else: focus stays where it was, no text changes, and a live region is the only channel the outcome can travel through. Each column's card stack is now `role="list"` with an `aria-label` carrying the count — `"To Do, 3 cards"`, and **`"Backlog, 0 cards"` for an empty column**, which previously had no badge, no cards and no name at all — and each card is `role="listitem"`. The board renders one `role="status" aria-live="polite"` region and listens for `bali:sortable-list:end`, so a drop announces "Design landing page moved to Done, position 1 of 2". Confirmed by dragging a card between columns for real and reading the tree afterwards; the sentence is a translated template (`bali_view.kanban.card_moved`) interpolated in JavaScript, because the interpolation happens in the browser. `Bali::Kanban::Card` takes a `label:` for boards whose cards lead with a date or an avatar rather than a title, and every card gains `role="listitem"`, so a selector naming a bare `.card` inside a column still matches but one asserting the absence of a `role` does not. Registering the new `kanban` Stimulus controller is automatic through `registerAll`; an app that registers controllers one by one needs to add it. **The board gains an outer `<div class="kanban-component">`** to hold the controller and the region — the grid used to be the root element, so a host that made the Kanban a flex or grid *item* is now positioning that wrapper instead; `class:` still lands on the grid, where it always did.

  **`SortableList`'s `bali:sortable-list:end` event carries more detail.** It used to dispatch `{ order, toListId }`, and `order` is the *source* list — SortableJS fires `onEnd` on the instance the item left — so a listener had no way to reach the destination. It now also carries `item`, `from`, `to`, `oldIndex` and `newIndex`. Purely additive; existing listeners are unaffected.

  **What this does not do, and it is visible.** The column's `aria-label` is rendered on the server, so after a client-side drop it is as stale as the count badge next to it — both say "3 cards" until the page re-renders. That is deliberate: making only the screen-reader label live would have it disagree with the number a sighted user is looking at, and the drop announcement already carries the new position and total. Hosts that PATCH through `update_url` and re-render get both refreshed together.

### Added

- **The five page components take a `context:`, and one view now serves the full page and the drawer.** "The same view serves a page and an overlay" is the one gesture of the Modal/Drawer contract that Bali did not help with at all, and hosts paid for it by writing the same render twice. Across `afal-apps`, 43 views branch on `drawer_request?`; 40 of them render a `FormPage`, all 40 pass `card: false` in the drawer arm, and 42 pass a `back:` in the page arm. **The two arms of that `if` differ by exactly two arguments** — roughly eight duplicated lines per template, and templates come in `new`/`edit` pairs, so about sixteen per resource. `context:` collapses the pair into one call:

  ```erb
  <%# before %>
  <% if drawer_request? %>
    <%= render Bali::FormPage::Component.new(title: t(".title"), card: false) do |page| %>
      <% page.with_body do %><%= render "form" %><% end %>
    <% end %>
  <% else %>
    <%= render Bali::FormPage::Component.new(title: t(".title"), back: { href: vendors_path }) do |page| %>
      <% page.with_body do %><%= render "form" %><% end %>
    <% end %>
  <% end %>

  <%# after %>
  <%= render Bali::FormPage::Component.new(title: t(".title"), back: { href: vendors_path }) do |page| %>
    <% page.with_body do %><%= render "form" %><% end %>
  <% end %>
  ```

  `context:` is `:auto` by default and can be forced to `:page` or `:drawer`. **Autodetection is the default and forcing is possible, rather than autodetection being the only mode**, because a component that changes its render according to the request stops being a function of its arguments — the explicit values keep that property where it matters, and they are the only way a test or a Lookbook preview can pin the variant without simulating a request. In a drawer the component drops the **breadcrumbs**, the **back button** and — on `FormPage` — the **Card**: the first two are ways *out* of a page, and a drawer is closed rather than left; the Card is the panel the drawer already draws.

  **The component does not read `params`, and that is the load-bearing decision.** `Bali::LayoutConcern` — which until now defined one method that nothing in the repository called except its own test — gains `drawer_request?` (`params[:layout] == "false"`, the value its layout switch has always read) and exposes it as a helper; `conditionally_skip_layout` is written in terms of it now. `context: :auto` asks the *view context* for that helper and renders a page when it is not there. The consequence worth the paragraph: **an app whose controllers already declare a `drawer_request?` helper — the exact pattern this replaces, since that helper is what the deleted `if` was calling — gets autodetection with no change to a single controller.** A view context that declares nothing (a Lookbook preview, a unit test, a mailer) renders a page, which is why this is additive rather than a behaviour change for anyone who is not opted in.

  **The escape hatches are real, and every arrangement is reachable.** `card:` is an ordinary argument and always wins — `card: true` inside a drawer included — which is why its default became `nil` ("let the context decide") rather than `true`. `back:` and `breadcrumbs:` go the other way and are suppressed *even when passed*, because the whole point is that the one surviving call site does pass `back:`; their escape hatch is `context: :page`, which restores the full page chrome inside a drawer request. Combine the two (`context: :page, card: false`) and nothing is walled off. `page.drawer?` is public and yielded with the component for the differences that are behavioural rather than chrome — a Cancel that *closes* an overlay and a Cancel that *navigates* are two different elements — so a partial takes `drawer: page.drawer?` instead of reading `params`.

  **What breaks for a host that updates.** One thing, and only inside an overlay: a `FormPage` rendered under `?layout=false` that passed **no** `card:` used to draw a Card and now does not. Every branching view in `afal-apps` passes `card: false` explicitly in that arm, so the measured blast radius there is zero, and `card: true` restores the old render. Everything else is additive — `context:` is a new keyword whose default reproduces today's behaviour outside an overlay, and a host that keeps its `if` keeps working untouched.

  **Proof rather than theory: the eight branching views in `spec/dummy` were migrated.** Five of the eight `if params[:layout] == 'false'` blocks are gone outright — the two admin `FormPage` templates, the two `studios` form templates (promoted from a bare `PageHeader` to `FormPage`, which is why they also gain `FormPage`'s `max_width: :md`) and the Card branch inside `studios/_form`. `studios/show` moved to `ShowPage`, which shares the whole mechanism because `context:` lives in `PageComponents::Shared` alongside the chrome it governs; `IndexPage`, `DashboardPage` and `DocumentPage` inherit it for the same reason, and it is inert for them until a drawer actually fetches one. **The three branches that remain are deliberate and are not layout branches**: a Cancel/Close button that dismisses an overlay versus one that navigates. `context:` does not absorb those — a page component decides its own chrome, not what the host's buttons do — and they read `page.drawer?` now rather than `params`. The dummy's controllers moved onto `Bali::LayoutConcern` at the same time, which deleted two hand-copied `drawer_request?` definitions and ten `render layout: !drawer_request?` calls; `Admin::BaseController` declares `self.conditional_layout = "admin"` instead of `layout "admin"`, since a `layout` call in a subclass overrides the concern's and takes the layout skipping with it.

  **Lookbook cannot issue a drawer request**, so the drawer variant would have had no visual coverage at all if the context could only be autodetected. `FormPage` and `ShowPage` each gained a "Page or drawer" scenario that forces it, with `card:` exposed as a param so the escape hatch is visible too.

### Deprecated

- **`Bali::Level` and `Bali::InfoLevel`** now warn through `Bali.deprecator` and are removed in 4.0. Neither is deleted here: the warning fires on construction and the render is the one it always was. `Level` is a flex row with `justify-between` and nothing else, so `<div class="flex justify-between items-center gap-4">` does the same without a component in between — and for a page header there is `Bali::PageHeader`, which is what Level was holding up. `InfoLevel` is the repo's third stat-card design: every `InfoLevel::Item` is a label on top of a large figure, which is a `StatCard` in different type; the replacement is a grid of `Bali::StatCard`, which is also what `DashboardPage#with_stat` renders as of v3.

  **PageHeader still uses Level internally and silences the warning** (`Bali.deprecator.silence` around the `.new`). That is not an oversight: were the warning to escape from there, a host that never wrote `Bali::Level` would collect one deprecation per page header, about a decision that is not theirs and that they cannot act on. Replacing that Level with plain flex is PageHeader's own work. A test fails if the warning leaks again.

- **`Bali::DocumentPage`'s `preview` slot** warns and is removed in 4.0. Rename it to `with_body`; see the page components entry above.

- **`Bali::FilterForm.simple_filter`** now warns through `Bali.deprecator` and is removed in v4. It is *not* removed in v3: the six apps hold 118 call sites of it, so a removal here would have been a rewrite of every filter form in the group rather than the hygiene pass this was. Declare `filter_attribute :status, type: :select, input: :slim_select, simple: true, advanced: false, options: [...]` instead — `collection:` becomes `options:`, the old `type:` (which named the widget) becomes `input:`, and `type:` now names the data type that drives the advanced UI's operators. The point of migrating is `advanced:`: one declaration can feed both the inline SimpleFilters row and the Filters popover, which `simple_filter` structurally cannot. Behaviour is otherwise unchanged.

### Changed

- **BlockEditor** - the declared `@blocknote/*` peer range moves from `>=0.51.0` to `>=0.52.1`, and for the first time it names a version that is actually under test. The three numbers were never the same: the peer said `>=0.51.0`, `spec/dummy` ran `0.46.2`, and no version inside the declared range had ever been exercised — the range was an aspiration, and the flush-on-submit written against 0.51's synchronous serialisers had only ever run on a 0.46 that still returned promises for some of them. `spec/dummy` now pins all seven `@blocknote/*` packages to `0.52.1` (the latest published), and the peer bound is that same 0.52.1 rather than a looser `>=0.52`. **For a host this is a breaking bump if it is below 0.51:** the submit flush has to write the hidden input *during* the `submit` event and cannot await, so it requires the synchronous parsers and serialisers that only exist from 0.51 on. A host on 0.51.x will most likely keep working — nothing in the component reaches for a 0.52-only API — but it is outside the declared range, outside what is tested, and `yarn`/`npm` will warn. Upgrade every `@blocknote/*` package together: mixing versions across `core`/`react`/`mantine` is not a build error, it surfaces as a menu that never opens or content that silently fails to serialise. Verified by hand on 0.52.1 (typing, bold/italic, bullet and numbered lists, slash menu, table insertion with a `|` inside a cell, `@` mentions, image upload through Active Storage, two-step undo, and the submit flush measured at 3 ms — hidden input still empty after the edit, populated the moment `submit` fires), plus the four paid XL packages exercised on the showcase page: multi-column schema loaded, `Ask AI` slash item present, PDF and DOCX exporters producing valid blobs. Two upstream table-corruption bugs present in 0.47 are confirmed fixed: `A|B` in a cell now round-trips through Markdown as `A\|B` and the table keeps its column count. **Not done here:** coordinating the `0.47 → 0.52` upgrade of the gobierno-corporativo application, which is a separate repository and a prerequisite for its own adoption of v3; and clearing the licence posture of the four `GPL-3.0 OR PROPRIETARY` XL packages, which needs the legal team and is blocking for GA. The measurable licence facts — which package declares what, where each is reached from, and that none of them ships inside the published `bali-view-components` package — are written down in `docs/api/block-editor.md`, explicitly separated from the unverified restatement of BlockNote's commercial terms. The 0.46 → 0.52 move changes no licence string on any of the seven packages. **One more consequence a host inherits: Node >= 22.** `@blocknote/core` 0.52 depends on `lib0` `1.0.0-rc.22`, whose `engines.node` is `">=22"`, so an app that renders the BlockEditor needs Node 22 to *install* — on Node 20 `yarn install` stops with `Found incompatible module` before anything runs, which at least means you find out immediately rather than in production. This repository's `test` and `cypress` workflows move from Node 20 to 22 for that reason; `standardjs` stays on 20 because it only installs the root lockfile, which has no BlockNote in it. `lib0` is the only package in the whole tree that asks for 22.

- **Tooling** - the dummy app and the repo's own dev dependencies drop five packages nothing imports. `interactjs` was never imported — `interact-controller.js` hand-rolls its pointer handling — and `@popperjs/core` only ever arrived through tippy.js, which depends on it directly, so declaring it bought nothing. `playwright` had no config, no specs and no CI step. `@babel/plugin-proposal-class-properties`, and its entry in `babel.config.json`, is redundant: class fields are ES2022 and `@babel/preset-env` has compiled them since 7.14. `@mantine/utils` is a vestigial peer declaration of `@blocknote/mantine` 0.46 that no `@blocknote/*` bundle actually imports — BlockNote drops the declaration in 0.51, so the unmet-peer warning `yarn install` used to print for it is gone now that the dummy runs 0.52.1 (#699). No effect on the published gem.

- **The migration guide is audited against this changelog, and four of its recipes were finding nothing.** `docs/guides/migration-v2-to-v3.md` grew one PR at a time across 32 merges and nobody had checked it as a whole, so the audit crossed every breaking and deprecated entry here against the guide's sections and then ran all 64 of its `grep` recipes against the four apps in the group. Coverage of the API surface turned out to be complete — every removal, rename and raise has a section — but the recipes that find the call sites did not work.

  **One recipe aborted before it ran.** `grep -rn "openModal\|openDrawer\|modal:success" app/ --include=*.js …` leaves the globs unquoted, and zsh — the default shell on macOS since Catalina — tries to expand `--include=*.js` itself, matches nothing, and kills the command with `no matches found` before grep starts. Measured on afal-apps: **0 hits where the same pattern finds 18**, and this is the recipe for the event renames, which the guide itself flags as the break that produces no error at all. The globs are quoted now, and `*.jsx` was added because the React islands in the group dispatch these events too.

  **Nine recipes of the shape `grep -rn "X::Component" app/ | grep option:` only ever matched call sites written on a single line.** A multi-line render puts the two halves of the pipe on different lines and the pipe sees neither. Measured against a parser that walks balanced `.new(…)` calls: `StatCard(icon_name:)` is **45** call sites in afal-apps and the recipe reported **12**; `with_tab(href:)` is **20** and the recipe reported **zero**, on the change where mixing `href:` and panels *raises*. They carry `-A6` now (`-A2` for the FormBuilder helpers, where a wider window pulls in the next field's `label:`), which reproduces the parser's count exactly for both. The same fix is a no-op for the recipes that were already right — `Link(type:)`, `Button(variant: :outline)` and the Bulma-name `Tag` scan return the numbers they returned before.

  **Eleven recipes named `spec/`, which none of the four apps has.** All four are Minitest; grep exits 2 and prints `spec/: No such file or directory` over the hits it did find. They read `app/ test/` now, with one line in the checklist telling an RSpec host to substitute.

  Three sections were missing and are written: **the tooltip** (#780 — the trigger becomes a tab stop when the slot holds nothing focusable, which is visible on every form field carrying a `tooltip:` and multiplies per row inside a listing), **`detail.id` on the overlay open events** (#784 — additive, and the answer for a page rendering a second overlay beside `AppLayout`'s shared `#main-modal`), and **five overlay behaviour changes with no API change** (#784 — `aria-labelledby` is conditional on the header slot, the panels take `tabindex="-1"` and focus resolves `[autofocus]` → first focusable → panel, Escape and Tab work during the skeleton fetch, and a 422 no longer clears the unsaved-changes flag). `Bali::ViewSwitch` swapping `aria-pressed` for `aria-current="page"` was also missing and is now a bullet: the component exists in v2, so a selector written against it really does stop matching.

  **Deliberately not written**, because they are not breaks and a guide that warns about migrations nobody needs stops being read: `FormPage`'s `card:` default moving from `true` to `nil` (it resolves to `!drawer?`, so a page request renders the card exactly as before, and the drawer case is already described under `context:`); the npm package gaining a `files` key (v2 already declared `exports`, so the importable surface is unchanged apart from `./gantt`, which the Gantt section covers); and the reference listing's third display mode changing its `?view=` value from `timeline` to `calendar`, which is the dummy app's own composition and not a library default. A second adversarial pass — every backticked identifier the changelog announces as removed or renamed, checked for presence in the guide — turned up two more with no mention anywhere: `Bali::HoverCard::Component::DEFAULT_Z_INDEX`, which now has its own paragraph under the z-index scale, and five page-component constants (the two `MAX_WIDTHS` that merge into `PageComponents::Shared`, plus `STAT_ICON_COLORS`, `DashboardPage::Stat` and `StatCard::Component::COLORS`), which get a line in *Removed constants* rather than a section because no app in the group references them. No code changes and no behaviour changes here — this is documentation only.

- **Tooling** - adelgazados los CLAUDE.md que se cargan en cada sesión (`CLAUDE.md` 47 → 29 líneas, `.claude/CLAUDE.md` 264 → 178). Se eliminó lo que una sesión puede reconstruir leyendo el repo: overview del proyecto, comandos estándar de Rails/Cypress ya presentes en `package.json`, la tabla de dependencias y sus comandos de update, el checklist pre-commit que `.githooks` ya impone (rubocop y minitest), el catálogo de iconos derivable de `lucide_mapping.rb`/`kept_icons.rb`, la lista de enlaces a documentación pública, y la sección "Session Memory" que describía hooks SessionStart/Stop que no están registrados en ninguna configuración. Se conservan íntegros los gotchas (Zeitwerk, Tailwind v4 layers, tooltip móvil), Prohibited Patterns y Component Composition. Los gotchas de BlockNote/ProseMirror se movieron a `app/components/bali/block_editor/CLAUDE.md`, que carga solo al trabajar en los componentes de editor. No effect on the published gem.

### Fixed

- **BlockEditor** - two editors on one page no longer fight over the upload-error toast. `useFileUpload` resolved its container with a global `document.querySelector('[data-controller="block-editor"]')`, which was wrong twice over. The selector is an exact attribute match, so it found nothing the moment a host put a second controller on the same element (`data-controller="block-editor analytics"`) and upload errors vanished with no trace. And with two editors it resolved to whichever came first in the document regardless of which one actually failed, so both toasts landed on the same `position: fixed` corner and the user could not tell which editor rejected the file. Errors are now appended inside the editor that raised them. A `two_editors` Lookbook preview covers the case, which nothing did before. No API change.

- **BlockEditor** - deleting a comment thread now removes its highlight from the document instead of leaving orphaned coloured text behind. `RESTThreadStore#_removeMarks` passed a freshly built `markType.create({ threadId })` to ProseMirror's `removeMark`, which matches on **every** attribute; BlockNote's comment mark carries `orphan` as well as `threadId`, so the rebuilt mark only matched while `orphan` happened to equal its default of `false`. Measured in the browser against the real schema: with `orphan: false` the old code removed the mark, with `orphan: true` it silently left it in place — and `orphan: true` is exactly what BlockNote sets on a comment whose thread it can no longer resolve, so the highlight survived precisely the case the code existed to handle. It now finds the real mark on the node, which also keeps overlapping comments intact where removing by mark *type* would have stripped every other thread's highlight in the same range.

- **BlockEditor** - `comments:` accepts `poll_interval:` (milliseconds, default 5000; `0` turns polling off). `RESTThreadStore` had always taken the option and nothing in Ruby could reach it, so every persistent-comments editor polled every five seconds whether or not the document had more than one author.


- **`CommandController`, `FeedbackWidgetController` and `FilterPersistenceController` are importable again.** All three were registered by `registerAll`, so their components worked — but none was re-exported from the package root, so a host could not import them to register one selectively, subclass one, or replace one. The root entry re-exported 61 of the 64 controllers `registerAll` registers and nothing anywhere compared the two numbers.

  **The cause was three hand-maintained lists per bundle.** `controllers/index.js` and `components/index.js` each carried a list of imports, a parallel list of re-exports, and a body of `application.register` calls that had to agree with both; the drift was invisible because every list was independently valid JavaScript. Each bundle now derives `registerAll` from a single frozen `CONTROLLERS` map of Stimulus identifier to controller class, which is the only place a registration is declared. Identifiers and named exports are unchanged — this is a refactor of the facade, not of what gets registered — and the map carries a `/* @__PURE__ */` annotation so a host importing one controller still tree-shakes the other 63.

  `scripts/check-controller-manifest.mjs` (also `yarn check:manifest`, and a step in the StandardJS workflow) now fails the build if a bundle's imports and its `CONTROLLERS` map disagree, if two bundles claim the same Stimulus identifier, if anything in a map is not re-exported from the package root, or if a `*Controller` class exists in the source tree that no map registers and no optional entry point exports. That last check is the one that would have caught these three, and the five controllers that legitimately ship from `./charts`, `./gantt`, `./block-editor` and `./rich-text-editor` are allowlisted by name against the entry that must export them, so an allowlist that stops being true also fails.

- **`Reveal#show` revealed nothing and `Reveal#hide` revealed everything.** The two methods were each other: `show()` *removed* `is-revealed` from the element and `hide()` *added* it, which is exactly backwards for a CSS contract of `hidden group-[.is-revealed]:block`. Only `toggle()` — the one path every preview and every test exercised — happened to work, because flipping the class is correct in both directions. Any host that wired `data-action="click->reveal#show"` got a component that hid on show and showed on hide, and nothing in the suite could see it. `toggle()` is now defined in terms of the two, so the three can no longer disagree, and both are idempotent (showing twice leaves it shown) where the old class-flipping `toggle` would have inverted a second call. The controller also keeps the trigger's `aria-expanded` in sync.

- **`Status`' options panel landed off screen inside a `Drawer`.** The panel is `position: fixed` so it escapes `DataTable`'s `overflow-x-auto` clipping, and `reposition()` set its `left` to the trigger's viewport x. That holds only while no ancestor carries a `transform`, `filter` or `perspective` — one that does becomes the containing block for its `fixed` descendants, and viewport coordinates stop meaning viewport. Bali's own `Drawer` animates with `transform: translateX(...)`, so a pill in a drawer got a `left` of ~1000px measured from the drawer's edge and the panel flew off the right of the screen; in a plain list it worked, which is why it survived. `reposition()` now probes for the offset instead of special-casing the drawer — it parks the panel at `(0,0)`, reads back where it actually landed (`0,0` under the viewport, something else under a transformed ancestor) and expresses the target position in that coordinate space — and clamps horizontally so the panel stays on screen either way. This is the fix `afal-apps` has been carrying as a full `reposition()` override marked `TODO(bali)`; that override can now be deleted on the version bump.

- **`TreeView`'s double navigation could not be reproduced, and is now pinned against.** The report — a click on a child navigating to its parent, because every ancestor's `click->tree-view-item#navigateTo` fires on the same bubbling click — describes what the markup implies but not what happens: Stimulus invokes a binding only when the event target's nearest controller element is the binding's own (`Scope#containsElement`), so ancestors never see a nested item's click. Verified end to end on the pre-change code: one handler runs, one `turbo:visit` fires, and it carries the child's URL. What did change is the link check, from `tagName === 'A'` to `closest('a')` — equivalent for the plain `link_to` this component renders, wrong the moment a host puts markup inside the link — and a `hasCaretTarget` guard, which the caret becoming conditional now requires: a childless item has no caret target and the old bare `this.caretTarget` read would raise. Cypress now covers the row click, the link click, the caret click and keyboard operation, asserting on the pages actually requested rather than on a stubbed `Turbo.visit` (which cannot be stubbed — it is a getter-only property).

- **`Timeago` raised on `nil`, and rendered an empty element without JavaScript.** `datetime.to_fs(:iso8601)` on a nil timestamp was a `NoMethodError` — reachable from any `last_seen_at` that no one has set yet — and even with a valid timestamp the server emitted `<time>` with no text at all, so the element was blank until Stimulus connected and permanently blank for a host that ships no JS or renders into an email. The relative time is now rendered server-side with Rails' `time_ago_in_words`, and the controller overwrites it with date-fns output on connect exactly as before. Only the suffix is Bali's to translate (`bali_view.timeago.ago`); the distance itself comes from Rails' `datetime.distance_in_words`, which this gem does not ship and must not squat on — a host that wants a localized first paint installs `rails-i18n`. A nil datetime renders `bali_view.timeago.blank` ("—") in a `<span>` with the same class and no controller attached, because a `<time>` without a machine-readable `datetime` is not a `<time>`. The controller also stops assigning `window.locale`, a global it wrote on every connect and nothing ever read.

- **`Heatmap` crashed on an unknown color and invented rows from string keys.** `resolve_color(:chartreuse)` looked the symbol up in `COLOR_PRESETS`, found nothing, and passed `nil` down to `ColorPicker.gradient`, which raised — a typo in a preset name took the page down instead of falling back. It now resolves to the default preset, as `Bali::Status` already did with its palette. Separately, y-axis labels were always built as `(keys.min..keys.max)`, which is right for the integer hour-of-day scale the component was written for and nonsense for anything else: string keys produced `("evening".."morning")`, a range of thousands of generated strings, and mixing integers with strings raised `ArgumentError` outright. Integer keys still get the filled range — that is the point, so an hour with no data still gets a row — and any other key type is now treated as a label and kept as given, in first-seen order, one row per distinct key.

- **`Chart` silently misread any data hash with string keys.** Every branch looks up `data[:labels]` and `data[:datasets]` by symbol, so the multi-series format written with string keys — which is what any payload that has round-tripped through JSON looks like — fell through to the simple `{ label => value }` branch and charted the *words* "labels" and "datasets" as its two categories, with the label array and the dataset array as their values. No error, just a wrong chart. The hash is now `deep_symbolize_keys`'d on the way in, which also fixes the `ArgumentError` a string-keyed dataset hash caused when it was splatted into `Chart::Dataset`'s keyword arguments.

- **Tooling** - `.claude/settings.json` no longer overrides the statusline with a dead path. The `statusLine` command pointed at `/Users/fede/code/shared/bali-view-components/.claude/statusline-command.sh`, an absolute path into a directory that exists on no machine — and since project settings win over user settings, it silently replaced whatever statusline each contributor had configured with nothing at all. Removed, so the user-scope statusline applies again. No effect on the published gem.

## [v3.0.0.beta.1] - 2026-07-31

### Changed (breaking)

- **DataTable + IndexPage — the index page becomes a default instead of an assembly kit.** Every listing feature added over the last cycles — saved views, row grouping, the column selector, export, the `ViewSwitch` segmented control — landed as its own isolated slot with its own isolated preview. None were ever composed together, so there was no single place showing what a Bali index is supposed to look like with everything on, and the pieces had drifted into three partially overlapping implementations of "display mode" and "export". v3.0 defines that composition and makes composing it wrong take effort. The canonical reference is rendered live: `bali/index_page/complete` in Lookbook (the same body without the page layer is `bali/data_table/complete`), the only place where all seven control families are on at once; `/admin/movies` in the dummy app is the same composition end to end against real controllers, routes and Turbo Streams, saved views included — the only family it leaves out is host toolbar buttons. Step-by-step instructions, including the two breaks that fail silently, are in [the v2 → v3 migration guide](docs/guides/migration-v2-to-v3.md).

  | Removed | Replacement |
  |---|---|
  | `with_actions_panel` | `with_bulk_actions` |
  | `with_actions_panel(export_formats:)` | `page.with_export(url:)` on the page component |
  | `dt.with_export` | `page.with_export(url:)` on the page component |
  | `with_actions_panel(grid_display_mode_enabled:)` | `with_view_switch` |
  | `Bali::DataTable::ActionsPanel::Component`, `Bali::DataTable::Action::Component` | *(deleted)* |
  | URL param `data_display_mode` | URL param `view` (rename with `view_param:`) |
  | `with_column_selector(table_id:)`, `with_saved_views(table_id:)` | resolved from `filter_form.storage_id` |
  | `Bali::Table(id:)` as the column-selector target | the DataTable container id |
  | `render Bali::Card` around the DataTable in the host | the content slot's surface |
  | `toolbar_class:` | *(deleted — the toolbar is bare by design)* |

  **The surface moved from the host to the component.** Each view used to write `render Bali::Card { render DataTable }`, so whether the toolbar sat inside a card depended on the page, and grid mode produced cards nested in a card. There is now ONE content band that decides its own surface: `with_table` brings a card plus `overflow-x-auto`, `with_grid` brings none (the cards *are* the surface), and `with_content(surface:, scroll:)` is the general form both are sugar over — a Gantt or a map passes `surface: false`. `display_mode:` no longer selects between two hardcoded slots: the host declares what it wants, so adding kanban, calendar or map views to an app requires no change in Bali. Declaring two content slots now raises `DuplicateContent`; in v2 the second silently won and the host got a mode it never chose. Hosts delete their `Bali::Card` wrapper — leaving it is not a crash, just a card inside a card.

  **One listing, one name.** A listing's identity used to be written four times (`Bali::Table(id:)`, `with_column_selector(table_id:)`, `with_saved_views(table_id:)`, `FilterForm(storage_id:)`), with the `#`-prefix normalization duplicated verbatim in two components; column persistence was keyed by `table_id` while the saved-views store was keyed by `storage_id`. `table_id:` is removed (passing it raises `ArgumentError: unknown keyword: :table_id`) and `DataTable` resolves the identity once: explicit `id:`, else `filter_form.storage_id`, else a random hex. The value is sanitized into a valid CSS identifier (case preserved; a leading digit gets a `listing-` prefix, because `#123 table` makes `querySelector` throw), the container renders with it, and the column selector targets `#<id> table` rather than the table element. Both controls derive their strings from the same place (`Bali::DataTable::ListingIdentity`): the saved-views controller finds the selector by comparing that exact attribute, so two separate derivations lost the columns on save without failing anywhere. With no stable identity (the random hex) column persistence turns itself OFF instead of writing a key nothing can ever read back.

  **The view switch replaced the legacy toggle, and preserves the query string.** `with_view_switch` puts a `Bali::ViewSwitch` in the toolbar, but the hrefs are built by the DataTable: each view declares `value:` and the component merges the current query string, dropping `page` and KEEPING `saved_view` — these links are navigation, not a filter submit, so filters, sorting, grouping and the applied view survive a mode change (in v2 each mode was a loose page and lost all of it). `dt.display_mode` returns the value validated against the declared views, so an unknown `?view=` falls back to the first one instead of leaving the listing empty. The active view now also travels as a hidden field on filter submits, the way `group_by` already did, so filtering from the cards view no longer drops the user back into the table. This retires `ActionsPanel`'s toggle and its competing export dropdown, which also closes **#653**: the toggle built its links with `Utils::Url#add_query_params`, whose Symbol-over-String merge duplicated a param already in the URL, and that code is no longer on this path.

  **Row selection belongs to the component.** `Bali::Table` gains `selectable: true`, rendering the checkbox column and select-all header every app used to hand-write; the `<tr>` is the selectable item (it carries `record_id:`, required, and the `selected` class) and it is mutually exclusive with the legacy `bulk_actions:` array (`IncompatibleOptions`). `with_bulk_actions` renders a `Bali::BulkActions(variant: :toolbar)` contextual row — counter, actions, clear — that REPLACES the toolbar row while a selection exists and restores it on clear, so the two never compete for space. This retires the `hidden md:block` desktop panel plus its `md:hidden` mobile COPY, the duplication that made two Stimulus controllers drive one listing. `Bali::BulkActions` gains `variant: :floating | :toolbar` and `standalone:`; the floating bar is unchanged and stays available outside a DataTable. The `bulk-actions` controller goes on the DataTable CONTAINER, never on the bar: two nested controllers of the same identity split the targets and the bar would never see the rows, silently. The controller now derives `selectedIds` from the DOM instead of counting incrementally — which is what keeps select-all, clear and a Turbo cache restore in sync with what is on screen — and gains `toggleItem`, `toggleAll`, `clear`, an indeterminate select-all and server-rendered plural labels (no i18n interpolation in JS). Note the payload: each action is its own form whose only hidden field is `selected_ids`, so a controller reading `params[:movie_ids]` or hand-written `name="x[]"` checkboxes stops receiving anything, and extra parameters travel in the action's query string.

  **The toolbar is one bare row, and it folds instead of duplicating.** Left is which data is shown, right is how it is shown, identical in every display mode. Below `sm` (640px) the secondary controls MOVE into a `⋯` menu and move back on the way up — never duplicated, because two copies of the column selector are two controllers driving one table and two copies of saved views duplicate the ids in its rename forms (the bug fixed in #669). The new `toolbar-overflow` controller is registered by `registerAll` and exported from the package root. Survival order (`OVERFLOW_PRIORITIES`): search/filters and the view switch stay; saved views, group by, columns, export and host `toolbar_buttons` collapse. It is a fixed `matchMedia` threshold, not measurement, and all state lives in the DOM, so a Turbo reconnect or a turbo-stream replace cannot strand a control inside the menu; `turbo:before-cache` always caches the expanded layout. Consequences: the toolbar order is now defined by `OVERFLOW_PRIORITIES` rather than by the template (expanding re-sorts by priority, which is what makes the controller stateless); the `⋯` is not rendered at all when nothing is collapsible, and is served hidden so it never flashes an empty menu; the view switch defaults to `icon_only: :responsive` (a new `Bali::ViewSwitch` mode that collapses only the label below `sm` while keeping `title`/`aria-label`, so the buttons never lose their accessible name); collapsible labels are marked `toolbar-control-label` so the new `data_table/index.css` can bring them back inside the menu, where there is room; and dropdowns nested in the menu render in flow, because absolutely positioned ones escaped the viewport on a phone. Anything a host puts in `with_toolbar_button` must have an idempotent `connect()` and no `data-turbo-permanent`.

  **Two things to check while migrating.** Users' stored column preferences reset ONCE, because the localStorage key changes from `bali:columns:<table_id>` to `bali:columns:<id>`; the old keys are orphaned and nothing cleans them up. That reset is also the fix for two different listings sharing one memory through a copy-pasted `table_id` (`/movies` and `/admin/movies` both used `#movies-table`). And the container id changed, so a host doing `turbo_stream.replace "data-table-#{@filter_form.id}"` must switch to `turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form)` — this is **the break that leaves no trace**: Turbo resolves the target with `getElementById`, so a miss replaces nothing, raises nothing and logs nothing. Target the RESOLVED identity, not the raw `storage_id`: it is the same string only when the `storage_id` is already a slug (`'admin/movies'` renders as `admin-movies`, `'2026_reports'` as `listing-2026_reports`), and `ListingIdentity.for` is the public entry point that applies exactly the component's rule. Render the DataTable from a partial shared by `index.html.erb` and `index.turbo_stream.erb` while you are there; the stream replaces the node that carries the selection controller, so the two branches have to produce the same DOM.

- **DataTable toolbar — the row is regrouped and gets a separator.** It now reads `search + filters · group by · columns ￨ saved views · persistence` on the left, with the view switch pinned to the right: **left is the state of the listing and how it is remembered, right is how it is displayed**. The display mode does not travel inside a saved view's payload, so the view switch is the only thing left on that side; saved views, the persistence bookmark and the column selector moved off the right. The `⋯` collapse behaviour is unchanged. Two things a host may notice. The home groups are now three — `left`, `memory` and `right` — so CSS or tests matching `[data-toolbar-overflow-group="right"]` for saved views or the column selector need to point at the new group; and `OVERFLOW_PRIORITIES` was renumbered (group by `40`, columns `35`, saved views `30`, persistence `25`), because the priority is not only the survival order: expanding re-sorts each group by descending priority, so it *is* the visual order inside a group. The numbers descend in reading order, which is what keeps the `⋯` listing collapsed controls in the same order as the row. The vertical rule between `columns` and `saved views` is deliberately NOT a control: it carries no priority and is not an `item`, so it can never travel into the `⋯`; the controller only hides it when a collapse empties either group it flanks, plus `max-sm:hidden` for the no-JS case. Empty groups are hidden as well — a group with no children is still a flex item and keeps stealing the row's `gap` from the search field on a phone.

- **Export leaves the DataTable toolbar and moves to the page's `⋯`.** `dt.with_export` is gone — calling it raises `NoMethodError`, on purpose — and the export now hangs off the surrounding page component: `page.with_export(url: movies_path)`. Exporting is an action ON the page, not a control of how the listing is displayed, and putting it next to the primary action is what gives import and print somewhere to land later instead of another loose toolbar button. `Bali::DataTable::Export::Component` stays where it is (same class, same `view_components.bali.data_table.export.*` scope) and remains usable standalone; what disappeared is the slot, `export` from `OVERFLOW_PRIORITIES` and the export branch of the toolbar's right group. Its `method:` keyword is also gone: under Turbo it only emitted a `data-method="get"` that does nothing, and the links now carry `data-turbo="false"` instead, because a CSV is not a response Turbo Drive can render — the visit used to stall halfway instead of starting the download. Hosts move one line from the DataTable block to the page block, and must answer the format: a controller whose `respond_to` only declares `html` returns 406 for `?format=csv`.

- **A sortable column now looks sortable.** `Bali::Table::Header` painted an arrow only on the column that was ALREADY sorted, because Ransack's `default_arrow` is `nil` — so every other sortable header rendered as bare text, indistinguishable from a fixed one, and the only way to find out a column could be sorted was to click it. Ransack's own indicator is switched off (`hide_indicator: true`) and the component builds the label: a dimmed `chevrons-up-down` on every sortable header that brightens on hover and on keyboard focus, and a single directional chevron at full opacity on the active one. The `<th>` also gains `aria-sort` (`ascending` / `descending` / `none`), which the table had never emitted in any form: the indicator is `aria-hidden`, so the state is announced once, by the right element — Ransack's old text arrow was read out as "black down-pointing triangle". Headers without `sort:` are untouched (no `aria-sort`, no indicator), and the sort href is unchanged. One trap if you extend this: `sort_link` merges every option that is not `class:` or `data:` into the HREF, so an innocent `title:` on the link comes back as `&title=...` in the sort URL; a test pins the query string to `q[s]` alone.
- **Page components get a first-class hole for secondary actions** — `page.with_secondary_action(**options, &block)` and `page.with_export(url:, formats:, params:)`, shared by all FIVE page components (`IndexPage`, `ShowPage`, `FormPage`, `DashboardPage`, `DocumentPage`) through `Bali::PageComponents::Shared`. They render a `⋯` dropdown next to the primary action, inside the same group; the menu is not rendered at all when nothing is declared, because a button that opens an empty menu is a bug. `with_secondary_action` takes the same options as `Bali::Dropdown#with_item` (it *is* an item of that dropdown, so it inherits the menuitem role and the Link/DeleteLink selection instead of every host re-writing them), and stores the ARGUMENTS rather than rendered content — the same pattern as `DashboardPage#with_stat`. `with_export` renders a section titled "Export filtered" with one item per format. Two consequences worth knowing: `renders_many :actions` moved up into the concern, so the four page components that declared it no longer do, and `FormPage` — the only one whose PageHeader carried no block — now renders an actions bar, which it never did before. Supporting pieces: `Bali::Dropdown` gains `tag: :title` (`Bali::Dropdown::Title::Component`), the section heading that lets a menu group items without opening a submenu, which the column selector and saved views were already hand-rolling; a menu whose only items are titles still does not render.
- **DataTable filter-persistence bookmark is its own toolbar control** — `Bali::Filters::PersistenceToggle::Component`. The bookmark that decides whether a listing remembers its filters used to be a button INSIDE the filters panel, and `Bali::DataTable::SimpleFilters` carried a hand-copied second version of the same markup inside its GET form. It is now one component the DataTable renders as an independent toolbar item, next to the filters node where it already sat, so the `⋯` menu can treat it on its own and the upcoming toolbar regrouping can move it without touching the panel. `Filters` and `SimpleFilters` gain `persistence_toggle:` (default `true`): used standalone they keep painting it exactly as before, and the DataTable forces it to `false` — two `filter-persistence` controllers over one `storage_id` fight over localStorage and the cookie. The flag turns off the CONTROL only; the panel still receives `persist_enabled` and keeps its "Auto-saved" hint. The DataTable captures the storage id RESOLVED by the slot rather than re-deriving it from the filter form, so a host passing `storage_id:` straight to the slot still gets a bookmark. Two side benefits: the toggle leaves the panel's `data-turbo-permanent` subtree (which the overflow contract forbids for anything collapsible), and the button finally has an accessible name — both its icons are `aria-hidden` svgs and `data-tip` is invisible to a screen reader, so it had none. New i18n key `bali.filters.persistence_label` ("Remember filters" / "Recordar filtros"); the existing `bali.filters.persistence_enabled` / `persistence_disabled` keys did NOT move, so host overrides keep working.

- **DataTable GroupByControl** - in a display mode that does not apply grouping the control now renders DISABLED instead of disappearing, and the banner that used to explain it ("Grouped by Genre — applies in Table view") is gone. Hiding it shifted the whole toolbar on every mode switch, and the banner spent a permanent strip next to the filters saying what a greyed-out button already says; the reason now lives in its `title`. The grouping is still suspended and the param still travels — only the affordance changed.
- **DataTable SavedViews** - you can now update a saved view from the UI. The only way to overwrite one used to be typing its **exact** name into "Save current view" and relying on the store's upsert — nothing said so, and a typo or a different capitalization silently created a second, near-identical view instead. With a view applied and the state changed, the primary action becomes `Update "<name>"` (with a confirmation, since it overwrites) and saving is demoted to "Save as new view". This needed a new `view_origin` param: `saved_view` *applies* a view — which is why #669 removed it from the filter forms, where preserving it re-applied the payload over what the user had just typed — so losing it also lost knowing which view the state came from. `view_origin` only remembers; it never applies. The `PATCH` endpoint now assigns only what was sent, so renaming can no longer blank the payload (`SavedView#payload=` slices, so a nil would erase the saved configuration in silence) and updating can no longer blank the name.
- **DataTable SavedViews** - the active view is visibly highlighted again. daisyUI 5 dropped the old `.menu li > .active` rule, so the component kept applying a class that styled nothing — and the tests kept passing because they asserted the class rather than the one that renders. The marker is now `text-primary font-medium`, the same way the sibling "Group by" dropdown (`GroupByControl#item_class`) and SlimSelect (`.ss-selected`) mark a selection: daisyUI 5's replacement, `menu-active`, paints the row with `neutral` — a solid black block that swallows the rest of the menu. (`Bali::SideMenu` is unaffected: it ships its own `.active` CSS.)
- **FilterForm** - a saved view that groups rows was never recognized as active by state matching. `current_view_payload` emitted `group_by` as a Symbol while a stored payload comes back from JSON as a String, and `comparable_view_state` normalizes keys but not values — so `:genre` never matched `"genre"`. Such a view only looked active while `?saved_view=` was still in the URL.
- **Filtering a select built on a Rails enum returned the exact opposite records.** Picking Status = "Done" listed only the Drafts. Ransack casts every condition value with the RAW column type (`Ransack::Nodes::Value#cast` via `Context#type_for`, which reads `column.type` and never consults ActiveRecord's `EnumType`), so on an integer enum `"done".to_i` is `0` — the code for `draft`. `Movie.where(status: "done")` gets it right because `EnumType` runs there; the same value routed through Ransack does not. It failed inverted and in silence, and half the filters looked fine by accident, because `"draft"` also casts to `0`. `FilterForm` now translates enum labels into their values in `ransack_params` — the single funnel both broken paths converge on, so it covers the `q[g][...]` groupings the Filters builder emits as well as declared attributes and simple filters — for `eq`, `not_eq`, `in` and `not_in` only, exactly the operators the select UI offers (a test pins the two lists together). Everything else is left alone on purpose: `_cont` asks for a substring and `_gteq` for an order over the raw codes, and translating there would replace one silent wrong answer with another. A RAW value passes through untouched, so an app already sending `0`/`1` is unaffected; anything that is neither a label nor a raw code matches NOTHING instead of passing through, because passing through is the bug — Ransack turns `"Done"`, a renamed member or a typo into `0`, the FIRST member of the enum, and the negated operators then return its complement. A blank value still means "no filter". The model is resolved through `defined_enums` rather than `scope.model`, so `FilterForm.new(Movie, params)` (the shape Ransack's own API teaches) translates like `Movie.all` instead of silently skipping the whole thing. The translation is the last step and works on a copy, so the rendered filter pills, the saved-view payload and the persistence cache keep speaking labels. String enums were never broken and the translation is idempotent there. **Association enums (`studio_status_eq`) are NOT translated** — resolving them means replicating Ransack's association resolution, and getting that subtly wrong reintroduces the same failure class — so a select over one returns the opposite records: declare its `options:` with the raw values until this is covered.
- **A hand-written `q[g]` returned a 500 on every index.** `extract_groupings` assumed the grouping param was always an `ActionController::Parameters` shaped exactly like the one Bali's own builder emits, and called `to_unsafe_h` on it. Ransack also accepts groupings as an ARRAY (`q[g][][status_eq]=done`), where that call raised `NoMethodError: undefined method 'to_unsafe_h' for an instance of Array`; a scalar group (`q[g][0]=x`, `q[g]=x`) got past the extraction and blew up inside Ransack instead. Any anonymous visitor could take down any listing in any host app by editing the query string. Groupings are now normalized on the way in — the array form becomes the indexed form the rest of Bali speaks, groups that are not hashes are dropped — which also puts the array form INSIDE the enum-label translation instead of letting it slip past and return the opposite records.
- **The dummy app could not demonstrate filter persistence, the feature it exists to show.** Applying filters, navigating away and coming back restored nothing, so the reference app looked like it shipped a broken feature — which is exactly the conclusion anyone evaluating Bali would reach. Nothing was wrong with the library: filter persistence writes to `Rails.cache` (`Bali::FilterForm#fetch_stored_filter_state`), and the dummy ran on Rails' development default of `:null_store`, upgraded to `:memory_store` only when `tmp/caching-dev.txt` exists. That file is gitignored (`/spec/dummy/tmp/`), so nobody who clones the repo has one, and nothing documented the toggle. A demo app needs a real cache store, so the dummy now sets `:memory_store` unconditionally; the `rails dev:cache` toggle keeps governing `perform_caching` alone, which is what it is actually for. Note for anyone testing by hand: the cache now survives between requests, so returning to a clean listing means clearing the `bali_persist_*` cookie or using "Clear all" — reloading without params restores, because restoring is the point. With a real store the key's shape starts to matter: it is `class;context;storage_id`, so WITHOUT a `context:` one key serves every request the process handles and one visitor's filters — and quick-search text — are restored for the next one. The dummy now passes a per-browser `context:` so the reference app demonstrates the isolated pattern a host will copy. No library code changed.
- **The toolbar folded by viewport, and a viewport says nothing about how much room the toolbar has.** The `⋯` collapsed on a fixed `matchMedia` under `sm`, so a listing in an app with a sidebar — 1024px window, 720px toolbar — never collapsed anything and instead squeezed the filters item, the only elastic one, down to **0px**. Its content kept its own width and painted straight over the neighbours: the search field, "Group by" and "Columns" all drawn on top of each other, with `scrollWidth === clientWidth`, no scrollbar and nothing on screen that reads as an error. It was broken from 640px to roughly 1400px and invisible to CI, because the Cypress spec tested 1280 and 375 in a Lookbook preview with no sidebar and asserted DOM membership, never geometry. Three changes: the controller now MEASURES (`max-content` against the row's real width) and moves controls into the `⋯` one at a time, lowest priority first, until the row fits — the breakpoint survives only as the mobile floor, where the result must not depend on how wide a translated label happens to be; a `ResizeObserver` watches the row, keyed on WIDTH only, because collapsing changes its height and reacting to that is the loop Chrome complains about; and the filters item gets a content-based basis above `sm` (`sm:flex-auto`) while the quick search gets `min-w-0`, so a row that is over-constrained shrinks the search instead of overflowing it on top of its neighbours. The `⋯` lost its `sm:hidden`, which used to hide it exactly at the widths where it is now the only way out.
- **A grouping picked from the URL was overwritten by the persisted one.** With filter persistence on, choosing a grouping arrives as `?group_by=genre` *alone* — the filters live in the cache, not the URL — so `fetch_stored_filter_state` took it for "nothing was submitted", ran the restore branch and replaced the fresh choice with the cached one (usually `nil`). The control did nothing when clicked, and coming back from cards to `?view=table&group_by=genre` dropped the grouping on the way. The URL now wins, the same way an applied saved view already did — and the choice is WRITTEN to the cache in that branch too, because rendering it without saving it fixed the same request and left the next one, arriving with no param, resurrecting the old grouping: the state that renders and the state that is stored have to be the same one. Related: **"No grouping" leaves `?group_by=` empty in the URL** instead of dropping the param, because an absent param means "restore the cache" and removing it resurrected the grouping the user had just turned off.
- **The display mode was derived twice and the two derivations disagreed.** `DataTable` resolves it against the declared views (an absent `?view=` falls back to the FIRST declared one); `FilterForm` read the raw param and treated `nil` as "grouping applies". They only agree when the first declared view is a grouping mode: a listing that declares Cards first landed with the grouping fully applied over the cards — group-first ordering, no bands, and a "Group by" control offering more of it — which is exactly what suspension exists to prevent. `group_by_modes:` could not fix it, because the `nil` escape short-circuits before the list is read. `FilterForm` gains `display_mode:` (pass what you pass the DataTable, e.g. `params[:view] || :grid`), and the DataTable raises `ArgumentError` when it resolves a mode outside `group_by_modes` while its form never saw one — the same fail-early it already does for a desynced `view_param:`. An unknown `?view=` still does NOT raise: a user can type it, and a 500 is not the answer to a typo.
- **A suspended grouping was invisible AND unremovable, and rode into saved views anyway.** Outside a grouping mode the control hides — the deliberate decision — but the state stays alive in the URL, in the filters cache and in the payload of a saved view, and the only control that could clear it was the one that had just disappeared. Saving a view from cards recorded a grouping the user could not see while naming it, and applying that view from the table grouped every row. `group_by_suspended?` existed for precisely this and nothing ever called it; the DataTable now paints the hint it was built for ("Grouped by Genre — applies in table view") where the control used to be. Still a hint, not a control: hiding the control is unchanged.
- **`group_by_modes: []` meant the opposite of what it says.** `.presence` turned an explicitly empty array into the default `[:table]`, so a host declaring "no mode applies grouping" got grouping applied in the table, with nothing on screen or in the logs to say the option had been ignored. `nil` and `[]` are now different answers, and `[]` also short-circuits the "no mode means it applies" escape.
- **Filters pushed a URL with every preserved param twice.** In popover mode the state hidden fields (`group_by`, `view`) render in BOTH forms, and `buildUrl` de-duplicated only the `q[...]` keys, so applying a filter left `?group_by=genre&view=grid&group_by=genre&view=grid` in the address bar. Rack takes the last value so nothing broke, but that is the URL the user copies and bookmarks — and it doubled again for every param a host adds through `preserved_params:`.
- **A dropdown announced "collapsed" with its menu on screen.** `aria-expanded` only tracked the keyboard path: opening with the mouse never calls `open()`, because daisyUI unfolds the panel through `:focus-within`, so the trigger kept saying `false` while the menu was visible (WCAG 4.1.2 — and VoiceOver's VO-Space dispatches a click, so this is not a mouse-only path). `Bali::Dropdown` now syncs the attribute with focus, which is daisyUI's real open signal; the `dropdown-open` class stays owned by the keyboard path that reads it. The two toolbar popovers built from a raw `<button>` — the column selector and saved views — had no `aria-haspopup` and no `aria-expanded` at all, and now carry both, kept up to date by the same rule.
- **The end-to-end reference page was missing two of the things it exists to demonstrate.** `/admin/movies` in the dummy app is what the migration guide points at, and it had no saved views and no way to sort by studio — so the composition it documented was not the one v3 describes. Saved views are now wired the way the guide says to adopt them: `saved_views_store: :default` plus `saved_views_owner: current_user` on the FilterForm, `dt.with_saved_views` with no `url:` (it falls back to the mounted engine routes), and `Bali.saved_views_owner` set in the initializer — that last one is not optional, because `Bali::SavedViewsController` does not inherit the host's `ApplicationController` and the default resolver's `controller.try(:current_user)` returns `nil` there, which 403s every save, rename and delete while the dropdown itself still renders fine. The Studio column becomes sortable through the association's Ransack path (`sort: :studio_name`), which is also what the canonical Lookbook preview now shows.
- **A dead quick search that answered 200 with every row.** The reference listing searched `name_or_genre_or_tenant_name_cont`, and `tenant` on that model is an `alias_method` for the `studio` association — a Ruby method Ransack cannot see. Ransack does not raise on an unreachable field inside a combined predicate: it drops the WHOLE condition, so typing anything into the search box returned the complete unfiltered set with no error, no log line and a 200. Fixed by searching the association's real Ransack path (`studio_name`). Worth internalising rather than just reading, because it is a property of Ransack and not of this app: one bad field kills the entire quick search, and only an assertion on the result SET can catch it — a request test asserting `assert_response :ok` passes throughout.
- **Export ignored the filters.** Exporting a filtered listing silently exported everything. `/admin/movies?q[name_cont]=dune&group_by=status` rendered `href="/admin/movies?format=csv"` — no filters, no search, no sort, no grouping — because `export_url` was `"#{url}#{separator}format=#{format}"` and hosts pass a bare path, so there was never a query string to carry. The user filtered a listing down to three rows, clicked export and got twenty, with nothing anywhere saying so. The href is now built with the shared `Bali::DataTable::ToolbarHref`, the same helper the group-by and view-switch links already used, so the export carries the same slice of data the user is looking at. Using the shared helper rather than `request.fullpath` is load-bearing twice over: `TRANSIENT_PARAMS` drops `page`, because exporting page 3 of a listing is never what "export" means, and drops `clear_filters`, which on the server runs `Rails.cache.delete(cache_key)` — a user sitting on `?clear_filters=true` would have wiped their stored filters as a side effect of clicking export. The new `params:` keyword decides the source: `nil` (default) reads the current request, an explicit hash overrides it, `{}` opts out and exports everything on purpose. Because the `⋯` now lives in the PageHeader — outside the node a filter submit's turbo-stream replaces — the links also carry a new `export-links` Stimulus controller that re-syncs their hrefs from `window.location` on connect; without it the first filter would freeze them on the slice from the initial page load and reintroduce the same bug through the back door. One caveat when verifying: with filter persistence ON and a clean URL, the correct href looks byte-for-byte like the buggy one (`/admin/movies?format=csv`) because the export request re-enters the same controller and restores the same state from the cache. Check it with persistence OFF, which is the default.

- **DataTable / BulkActions** - selecting a row no longer pushes the listing down. The contextual selection row replaces the toolbar in the same slot but measured 18px taller (`py-2` contributed 16, `border` 2), so every selection and every clear shifted the layout. The outline is now a `ring` (a box-shadow: zero layout cost) with no vertical padding, and both rows declare the same explicit `min-h-8` — the height of a daisyUI `sm` control, which is what the toolbar already measured by accident. A test pins the two constants together so they cannot drift. Because that leaves the row exactly as tall as an `sm` button, the contextual bar sizes its own actions at `xs`: inside a tinted surface of fixed height, `sm` buttons sit flush against the edges and read as cramped, while `xs` leaves 4px of air without changing the height. The floating bar has no such ceiling and keeps `sm`; an explicit `size:` on an action wins over both.
- **Pagination** - the current page was indistinguishable from the others. The markup was already correct (`btn-active` + `aria-current="page"`), but daisyUI 5's `btn-active` barely darkens a plain `btn`, so the page you were on looked exactly like the ones you weren't. It now carries `btn-active btn-primary`, the same marker the rest of Bali uses for "this is the selected one" (see `ViewSwitch::View`). The existing test passed throughout, because it asserted the class rather than the visible distinction; it now pins both.
- **Dependencies** - three security advisories cleared. `rails` 8.1.3 → 8.1.3.1 for CVE-2026-66066 / GHSA-xr9x-r78c-5hrm, possible arbitrary file read and remote code execution in Active Storage variant processing — the only one that reaches production code in a consuming app. On the JS side, `js-yaml` (5.2.1 → 5.2.2) and `brace-expansion` (5.0.4 → 5.0.9) clear two high-severity denial-of-service advisories (exponential parsing time in flow collections; exponential-time expansion of consecutive non-expanding `{}` groups); both are transitive dev dependencies, pinned through the existing `resolutions` block.
- **DataTable** - a host that declares `with_view_switch` but forgets `display_mode:` no longer gets a switch whose links change the URL and never change the view. `display_mode` now falls back to `params[<view_param>]` (the component already had the query string in hand — it builds those very hrefs with it) and then to the first declared view.
- **DataTable / GroupByControl / ViewSwitchControl** - the toolbar's navigation links no longer corrupt a `url:` that already carries a query string. `"#{url}?#{query}"` turned `admin_movies_path(scope: 'archived')` into `/admin/movies?scope=archived?view=grid`, which Rack parses as one corrupt `scope` and no `view`: the click did not change the view and poisoned the scope. Both controls now build the href through the shared `Bali::DataTable::ToolbarHref`, which parses the base URL and merges. Export, SavedViews and Filters already handled this shape.
- **DataTable** - the listing identity is now public as `Bali::DataTable::ListingIdentity.for(filter_form)`. The docs told hosts to target `@filter_form.storage_id` in `turbo_stream.replace` while the component renders the SANITIZED value, so any `storage_id` that is not already a slug pointed the stream at nothing — silently, which is exactly the failure mode that section of the migration guide exists to prevent.
- **DataTable** - the `⋯` gate now looks at what the toolbar actually RENDERS, not at which slots were declared. `with_saved_views` on a form without a store leaves `render?` false, but the slot predicate stayed true, so a phone got an empty wrapper inside the menu and a "More options" button that opened a blank panel.
- **DataTable** - the `⋯` panel is no longer declared as a menu. It holds whole widgets (nested dropdowns, column checkboxes, the rename form), and `role="menu"` exposed children that role does not allow and put screen readers in menu mode over a form. `Bali::Dropdown` gains `menu: false` for a generic popover container, and its keyboard handler now ignores events raised inside a NESTED dropdown (both controllers were processing the same keydown, so one arrow skipped two items and Escape inside an input closed the outer container) and inside form controls, where arrows belong to the field.
- **DataTable toolbar overflow** - crossing the breakpoint no longer drops keyboard focus on the floor. `closeOpenDropdowns` blurred the active element and the collapse moved it, leaving focus on `<body>` with no ring and no announcement — on a zoom to 400%, the 320px viewport WCAG requires. Focus is now restored to the same control, or to the `⋯` trigger when the control ended up inside the closed menu.
- **DataTable toolbar overflow** - `OVERFLOW_THRESHOLD` is emitted as the controller's `threshold` value instead of being duplicated as a JS default, so moving it cannot leave the server-side `⋯` gate and the client-side collapse rule disagreeing.
- **BulkActions** - selection changes are announced. The counter and the contextual bar changed with no live region at all, so a screen-reader user selecting rows got no confirmation the selection existed — and no hint that the toolbar with search and filters had just left the page (WCAG 2.1 SC 4.1.3). A `role="status"` region now lives permanently in the DOM (a region that appears together with its text is not announced).
- **BulkActions** - the clear (✕) button no longer throws focus to `<body>`. It lives inside the bar it hides, so activating it made the focused element `display:none`; focus now moves to the select-all checkbox, or to the first control of the restored toolbar.
- **ViewSwitch** - the active view is marked with `aria-current="page"` instead of `aria-pressed`. These are `<a>` elements that navigate, and browsers drop `pressed` on `role=link`: the active mode was expressed by colour only and the three links sounded identical to a screen reader (axe reported `aria-allowed-attr` on every one of them).
- **DataTable ColumnSelector / Export / SavedViews** - the trigger buttons carry an explicit `aria-label`. Their visible label lives in a `hidden sm:inline` span, so on a phone — until the JS moved them into the `⋯`, and forever if the bundle failed — they were icons with no accessible name. The saved-views label is computed, not static, so it never contradicts the visible text (Label in Name).
- **Table** - `selectable: true` no longer leaves the empty state one column short. The empty row's `colspan` used `headers.count`, which ignored the selection column and counted hidden headers.
- **Table Row** - `select_label:` gives the row checkbox the record's name. Without it every row's checkbox is called "Select row", and a screen reader's form-controls rotor lists N indistinguishable entries.
- **Filters** - the preserved-state hidden fields (`view`, `group_by`, host params) no longer produce duplicate element ids: in popover mode they are rendered in BOTH forms, and the id was derived from the name.
- **Filters** - clearing the search or the filters preserves the listing state. Both handlers rebuilt the URL from `urlValue` alone — which hosts pass without a query string — so the `view` hidden field this release added precisely to survive filter round-trips was dropped, and clearing a search from the cards view landed the user back in the table.
- **DataTable SavedViews** - applying a saved view keeps the current display mode (the view switch already preserves `saved_view`; the reverse direction did not), and saving a view from a mode with no column selector uses the columns the APPLIED view imposed rather than the device's older localStorage memory.

- **Export still ignored the filters in the one case it was written for.** The `export-links` controller re-synced the hrefs on `connect` and on `turbo:load`, and a filter submit answered with a turbo-stream fires neither: a stream render is not a visit, so Turbo dispatches no `turbo:load`, and the `⋯` lives in the PageHeader — outside the node the stream replaces — so the controller never reconnects either. Filtering `/admin/movies` down to one row and clicking "Export filtered" downloaded all twenty, exactly the bug the controller exists to prevent. It now also listens on `turbo:before-stream-render` and `turbo:submit-end`. Worth knowing when reading `Bali::Filters`: `data-turbo-stream="false"` does NOT turn streams off — Turbo tests that attribute for PRESENCE, so every Bali filter form asks for a stream response and any host with a `turbo_stream` template was on the broken path by default.
- **Export re-sync overwrote the server's decision.** `sync()` assigned the whole query string from `window.location`, so it deleted anything the server had put in the href and the browser did not have: a `url:` carrying its own params (`exports_path(kind: :movies)`) lost them and the download pointed at another data set, and `params: {}` — the documented "export everything on purpose" opt-out — was silently turned back into the filtered slice the moment Stimulus booted. Both cases had passing Ruby tests, because `render_inline` runs no JS. The controller now MERGES over the link's own query string (same rule as `ToolbarHref#build_toolbar_href`) and stays out of the way entirely when the host passed `params:` itself, which the server signals with `data-export-links-sync-value="false"`.
- **The export menu's section title was invisible to screen readers.** Inside a `<ul role="menu">` assistive tech navigates menuitems only — as does the component's own `DropdownController#getMenuItems`, which selects `[role="menuitem"]` — so the "Export filtered" heading was skipped and the three items announced as bare "CSV", "Excel", "PDF" with nothing saying they export anything. The title is now `role="presentation"` (a generic span is not a child `role="menu"` allows) and each format item points at it with `aria-describedby`, which adds the purpose without overwriting the visible label.
- **Filters persistence toggle** - the bookmark announces its state. It is a two-state control whose only state cues were an icon swap and `data-tip`, i.e. CSS generated content: the accessible name was identical on and off, and toggling reloads through Turbo without announcing anything, so a screen-reader user could not tell whether filters were being remembered, or which way they had just flipped it (WCAG 4.1.2). It now carries `aria-pressed`, kept in sync by the controller because `connect()` can flip the value from localStorage without a re-render.
- **DataTable toolbar** - host `toolbar_buttons` moved into their own overflow group (`host`). Sharing the `right` group with the view switch, the JS ordered both by priority (10 against 50) and the host button landed to the RIGHT of the switch — so the control that says how the listing is displayed was no longer the one pinned to the edge, contradicting both the layout rule and the docs. The canonical preview stopped declaring an `Import` toolbar button too: the page already declares `Import` as a secondary action, so the reference composition was teaching two homes for the same action.
- **DataTable toolbar overflow** - crossing the breakpoint UPWARD no longer drops keyboard focus. The previous fix only looked inside `item` targets, and the `⋯` trigger is not one: a keyboard user parked on it at 320px (a zoom to 400%) who returned to 100% lost focus to `<body>` — the mirror of the case the controller documents as unacceptable. The trigger now counts as a focus source, and when it disappears focus lands on the highest-priority control that just came back into the row.
- **Table** - the "this column is sortable" chevron is readable without a mouse. It sat at `opacity-30`, which compounds with the 60% daisyUI already applies to `thead`: ~1.5:1 against the surface, under the 3:1 WCAG 1.4.11 requires for a UI component. Its only escalation was `hover`/`focus-visible`, neither of which exists on touch, so on a phone it stayed there permanently — for exactly the users the affordance was added to help. It now uses an explicit colour (`text-base-content/60`) rather than stacking opacity.
- **PageHeader** - the `⋯` of secondary actions matches the height of the primary action next to it. It kept the `btn-sm` of the DataTable toolbar it came from, leaving it 8px shorter than the button it is glued to inside the same flex row.
- **A grouping stayed in force in card and timeline views, where nothing on screen could explain it.** Switching `/admin/movies?group_by=genre` to cards kept the group-first ordering running invisibly — the cards came back in a different order than the same URL without `group_by`, with no group bands to justify it — and the "Group by" control stayed offering more groupings that would do the same. Grouping now **applies in table mode only**: outside it the control hides and the grouping is **suspended**, while the `group_by` param **survives** in the URL and in the hidden fields of the filter forms, so switching back to the table finds it exactly as it was left (searching from card mode no longer wipes it). Under the hood the old single `group_by_active?` predicate split into three, because it was answering two different questions at once: `group_by`/`group_by_active?` is STATE and governs preservation (hidden fields, filters cache, saved-view payload); `group_by_applies?` is MODE and governs the control's visibility; `group_by_applied`/`group_by_applied?` is APPLICATION and governs ordering, `group_counts` and each row's `group:` value. Hosts painting group bands must read `group_by_applied` — `group_by` alone now paints bands the query is not ordered for. Two new `FilterForm` options tune it: `group_by_modes:` (default `[:table]`) and `view_param:` (default `:view`), which must match the DataTable's — a DataTable whose `view_param:` disagrees with its form now raises `ArgumentError` at build time, since desynced there is nothing visible to give the bug away.
- **Three toolbar controls, two different button styles — and two popovers opening away from their own buttons.** "Group by" was the only control in the row rendered as a `ghost` trigger (`btn btn-ghost btn-sm gap-1`) while filters, columns and saved views all wear `btn btn-outline btn-sm gap-2`: with no border it read as belonging to a different family, sitting between two bordered siblings. It now uses a new `outline` variant of `Bali::Dropdown::Trigger` — the enum already had `button`, `icon` and `ghost`, so the toolbar look had no name and the call site was the only place that could spell it out. Columns and saved views also dropped `dropdown-end`: both moved to the LEFT group of the toolbar in this same cycle, so a panel anchored to its trigger's right edge opened backwards, away from the row it belongs to. Export keeps `dropdown-end` — it moved to the right edge of the PageHeader, where right-anchored is the correct behaviour. Inside the `⋯` menu nothing changes: `dropdown-content` is forced `static` there, which makes every alignment class inert.

## [v2.18.0] - 2026-07-31

### Security

- **Dependencies** - `rails` 8.1.3 → 8.1.3.1 for CVE-2026-66066 / GHSA-xr9x-r78c-5hrm, possible arbitrary file read and remote code execution in Active Storage variant processing. This is the one advisory in the stack that reaches a consuming app's production code, so it ships with the stable line rather than waiting for v3.

### Added

- **DataTable SavedViews** - the dropdown now signals the ACTIVE view: the trigger button shows its name (with a filled bookmark icon) and the matching item gets the `active` class. Active is the view applied by URL (`?saved_view=`), or — because persistence rewrites the URL clean on the way back — the personal view whose payload matches the form's CURRENT state (`FilterForm#view_matches_current_state?`), or the static `default_views` shortcut whose URL query describes that same state. One winner, no double marking. The dropdown also gains `max-h-[70vh] overflow-y-auto` and full-width rows so long lists stay usable.
- **DataTable GroupByControl** - accepts explicit `options:`, `current:`, `param:`, `include_none:` and `label:`, so a surface whose grouping does not live in a FilterForm (e.g. a server-rendered Gantt with its own grouping param) can reuse the SAME "Group by" dropdown instead of hand-rolling a lookalike control. The FilterForm-driven path is unchanged and remains the default.
- **DataTable** - `toolbar_class:` adds classes to the toolbar row (filters + actions). Lets a host wrap ONLY the toolbar in card surface when the content brings its own (a card grid, a Gantt) without duplicating the component.

### Fixed

- **DataTable SavedViews** - the `saved-views` Stimulus controller shipped with the component but was never registered (nor exported) by `registerAll`, so "Save current view", rename and the column-capture on save were dead in every host app. It now registers alongside `column-selector`.
- **Filters** - the persistence toggle no longer promotes a server-rendered `false` into a durable user preference. `connect()` synced the cookie unconditionally, so merely VISITING a listing where persistence is off by context (a deep-link that disables restoring, e.g. a triage view) wrote `bali_persist_<id>=0` for a year — and rewrote it on every visit, silently disabling the feature everywhere until the user found the bookmark button. Only an explicit toggle (which is what writes localStorage) may write the cookie now.
- **Filters** - submitting the quick search no longer flips an applied `OR` to `AND`. The hidden `q[m]` carried the COMPONENT's default (`:and`) rather than the applied combinator, so a two-group OR silently narrowed to AND on the next search — and with persistence on, the corrupted state was written to the cache. `combinator:` now defaults to nil, DataTable auto-populates it from the FilterForm's applied value (new `FilterGroupParser#applied_combinator`), and `q[m]` is emitted only when the state actually carried one.
- **Filters** - a `between` condition with both ends blank no longer emits a phantom group. `{start: "", end: ""}` is a Hash, so it passed `present?` and produced `q[g][i][m]`/`q[m]` with no condition at all — enough for the server to treat "search only" as "new filters" and cache a ghost state.
- **Filters** - `saved_view` joins `EXCLUDED_PARAMS`. When a host passes the current URL as `url:`, preserving it made the server re-apply the view's payload on the next submit, silently discarding the filters or search the user had just typed.
- **Filters** - the pushed history URL no longer describes the PREVIOUS filter. `buildUrl()` appended the popover form's params and then the search form's, which since the hidden-field fix carries the applied state too — on nested parse the last key wins, so editing or removing a condition and applying left the old one in the URL (definitive under `turbo_stream: true`).
- **DataTable SimpleFilters** - same tooltip fix as `Filters`: the localized texts sat on the button child where Stimulus never looks, so `connect()` overwrote the server-rendered `data-tip` with the English fallback on every load.
- **DataTable SavedViews** - a view whose payload normalizes to EMPTY (the headline "save my column layout", or a "show everything" view) no longer matches by state. It described the clean state, so it was marked active on every visit while its columns were NOT applied — `columns` only applies via `?saved_view=`. Such views are recognized only when applied by URL.
- **DataTable SavedViews** - a shortcut or view stays marked after a round-trip through the builder or the search box. The builder always re-emits `m` per group (and `q[m]`) even when the original state carried none, which broke the comparison; no-op combinators (a single-condition group, a single group) are now normalized away — never where AND vs OR actually changes the result.
- **DataTable SavedViews** - `default_views` matching now understands `group_by` (a top-level param, outside `q`) and the quick-search predicate (which the form keeps in `search_value`, not `attributes`). Translating less produced both false positives (a grouping-only shortcut normalized to empty and matched anything) and false negatives (a search shortcut never matched).
- **DataTable SavedViews** - the rename inputs get unique ids; N views produced N+1 duplicate `id="name"` (invalid HTML, confused autofill).
- **DataTable SavedViews** - saving from a mode without a column selector in the DOM (a card grid, a Gantt) now falls back to the selector's per-device memory instead of dropping `columns`, so a view no longer "forgets" half its state depending on where it was saved from.
- **FilterForm** - the persisted state now includes `group_by`. Coming back to a listing restored the filters but lost the grouping, and a saved view that groups stopped being recognized as active.
- **FilterForm** - clearing the search no longer restores cached state when persistence is OFF. That branch read the cache before the `persist_enabled` check, so the clear-search button became a back door for filters the URL no longer described.
- **FilterForm** - an explicit `group_by` in params now wins over an applied view's payload. With `?saved_view=` still in the URL (the grouping links preserve the query), the payload overwrote the click and the control looked dead.
- **DataTable** - explicit `preserved_params` MERGE with the active `group_by` instead of replacing it; a host preserving its own params silently dropped the grouping on every filter/search submit.
- **DataTable GroupByControl** - the one-shot commands (`clear_filters`/`clear_search`) no longer ride along in the option hrefs. They are actions, not navigation state: carrying them re-executed the wipe on every later grouping click, and a shared link repeated it on every open.
- **DataTable GroupByControl** - the trigger gets an explicit `aria-label`: its text lives in a `max-sm:hidden` span, leaving an icon-only button with no accessible name on mobile.
- **JS entry** - `ColumnSelectorController` is exported from the package root alongside `SavedViewsController`; selective imports of it failed to build.
- **Filters** - submitting the quick search no longer WIPES the applied filters. The search form only carried the search input, so the server read "empty attributes + new search" as the new state — clearing active filters on screen and, with persistence on, overwriting the stored state too. The applied `q[g][...]`/`q[m]` state now travels as hidden fields in the search form (the consolidated `between` operator expands back to its `gteq`/`lteq` pair; empty builder rows stay out).
- **Filters** - the persistence toggle tooltip ignored the localized texts and always fell back to hardcoded English ("Filter persistence enabled…"). The controller read `this.data.get(...)` on its own element while the ERB placed the attributes on the button CHILD, where Stimulus never looks. The tooltips are now proper Stimulus values on the controller element.

### Added

- **DataTable saved views (B2)** — named filter combinations. `Bali::FilterForm` gains `saved_views_store:`, a `list/find/save/delete` contract (Bali defines the WHAT, the store decides the WHERE — same spirit as the `Rails.cache` persistence); `?saved_view=<id>` REPLACES the filter state with the view's payload (attributes gated by the declared ones, `group_by` re-passes the whitelist) and flows through the normal persistence so the applied view becomes the listing's last state — always overwriting it: an applied view whose payload is EMPTY (a "show everything" view) also beats stale cached filters instead of being mistaken for "no filters submitted". New `Bali::DataTable::SavedViews` component (`with_saved_views` slot): apply/save-current/rename/delete, plus static `default_views` shortcuts ("Suggested" section). The column selector gains per-device persistence (localStorage keyed by table) and visible columns travel INSIDE the saved view (a Stimulus controller injects them on save; an applied view wins over the device memory).

  The engine SHIPS the default implementation of that contract, so adopting saved views in an app is: `bin/rails bali:install:migrations && bin/rails db:migrate`, mount `Bali::Engine`, and `dt.with_saved_views` on a DataTable whose FilterForm passes `storage_id:` plus `saved_views_store: :default, saved_views_owner: current_user` — zero models, controllers or routes in the app. Pieces: table `bali_saved_views` (POLYMORPHIC `owner` on purpose: phase 2 — team/role views — changes the owner, not the schema; `jsonb` payload on PostgreSQL, `json` elsewhere), model `Bali::SavedView` (payload sliced to the FilterForm contract, accepts Hash or JSON string, invalid JSON → `{}`), `Bali::SavedView::Store` (scoped to one owner + one `storage_id`, upsert by name; also reachable as `Bali::SavedView.store_for(owner, storage_id)` for the explicit one-liner), and `Bali::SavedViewsController` (create/update/destroy; everything scoped to the owner — a foreign view is a 404, never a 403 that confirms existence). The engine controller does NOT inherit the host's ApplicationController hooks, so authorization lives in config: `Bali.saved_views_owner` (default `controller.try(:current_user)`) resolves the owner and `Bali.saved_views_authorize` (default: owner present, otherwise 403) gates every mutation. That also means a `current_user` living in a host concern (bali-auth's case) does not exist on the engine controller by itself — the host either teaches it (`Bali::SavedViewsController.include YourAuthConcern` in a `to_prepare`, skipping the concern's own before_actions) or configures `saved_views_owner`. When `with_saved_views` gets no `url:`, it defaults to the mounted engine routes with the form's `storage_id` in the query string (no `storage_id` → the dropdown does not render). An app-provided store still works unchanged — team-shared views remain just another store implementation.

- **BlockEditor** - the install boilerplate every consuming app had to write by hand now ships with Bali (extracted from the first real adoption, in afal-apps). Three pieces: `bali-view-components/block-editor-entry`, a self-registering bundler entry that turns the app's `editor.js` into a single import (it registers on the existing `window.Stimulus` — a standalone bundle starting a second Stimulus application mounts every controller twice); `bali-view-components/block-editor-loader`, a tiny module for the MAIN bundle that watches the DOM and injects the editor's `<link>`/`<script>` the first time a `block-editor` appears — necessary because drawers inject content with `innerHTML`, where `<script>` never executes, so a view-level `<script>` silently left the editor unmounted; and `Bali::BlockEditorHelper#block_editor_meta_tags`, exposed to host views by the engine, which publishes the digested asset paths the loader reads (only the server knows them). The meta names are now a contract inside one library instead of a convention copied between apps.

### Fixed

- **Engine** - v2.17.0 broke EVERY host app at boot with `uninitialized constant Bali::BlockEditorHelper`. Two stacked causes, each invisible in this repo: (1) the engine assigns (not appends) its `eager_load_paths` and `app/helpers` was not on the list, so the constant was not autoloadable in a host — masked here because Lookbook pushes the engine's dirs into the dummy's autoloader; (2) the helper was exposed via `on_load(:action_controller_base)`, and any host that loads `ActionController::Base` during boot (any gem requiring it does) fires that hook before Zeitwerk is set up, so the constant raises even with the path declared — masked here because the dummy never loads it that early. `app/helpers` is now declared, the exposure moved to `config.to_prepare`, a test pins the engine config itself, and the fix was verified against a real host app.
- **BlockEditor** - the header comment of `bali-view-components/block-editor` told installers to `yarn add @blocknote/xl-multi-column` — one of the paid GPL-3.0/commercial packages that v2.16.0 deliberately removed from `peerDependencies`. It now lists only the free packages.
- **SlimSelect** - `include_blank`/`prompt` on a GROUPED (optgroup) option list no longer destroys the list. The placeholder promotion shipped in v2.16.0 prepended a flat option, and Rails decides between `options_for_select` and `grouped_options_for_select` by looking only at the FIRST element — so every optgroup was flattened into garbage options and `selected:` stopped matching. Grouped lists keep Rails' plain `include_blank` behavior (the blank renders as a regular option, as before v2.16.0); flat lists keep the placeholder promotion.
- **BlockEditor** - an application that installs only the free MPL-2.0 packages can now BUILD. The four paid `@blocknote/xl-*` packages and their companions (`ai`, `docx`, `@react-pdf/renderer`) were loaded through `import()` calls nested inside `Promise.all([...])`. esbuild only treats a dynamic import as optional when it can attribute the failure to a surrounding `try`, which it cannot do for an import in an argument list — so it demanded all of them at BUILD time, even for an app that never enables AI or exporting. Measured on a real app: `yarn build` failed with **27 errors**; after awaiting each import on its own line it builds clean. This matters beyond ergonomics: those four packages are `GPL-3.0 OR PROPRIETARY`, so "just install what the library asks for" quietly pulled a closed-source app into a paid commercial licence. Same fix applied to `shiki`.
- **BlockEditor** - compatible with BlockNote >= 0.51 again. Its parsers stopped returning promises in 0.51, and the HTML path still called `.then()` on the result, which throws on a plain array. The peer range moved to `>=0.51.0` for a second reason: 0.47 corrupts table data in two ways (a `|` inside a cell is not escaped on export, so re-parsing drops a cell; and a table with no header row promotes the first data row to a header).
- **BlockEditor** - a form submitted within the 500 ms sync debounce posted the PREVIOUS content, losing the user's last edits with no error. The controller now also flushes on the form's `submit` event. Drawers that submit over fetch hit this on every fast save.
- **BlockEditor** - the editor rendered in English regardless of the application locale. It now follows `I18n.locale` (BlockNote ships ~23 locales) and accepts an explicit `locale:`.
- **BlockEditor** - documentation corrected: the import example named the package root, which does not export `BlockEditorController` (the subpath `bali-view-components/block-editor` does), and two passages claimed the XL packages had no build-time cost.

### Added

- **BlockEditor** - `format: :markdown` with a matching `markdown_content:`, serialising through `blocksToMarkdownLossy` / `tryParseMarkdownToBlocks`. This is what lets an application adopt the editor WITHOUT migrating stored data: search, plain-text exports, APIs and LLM prompts keep reading the same column. Verified against 14 real documents: 12 round-trip word-for-word, GFM tables and nested checklists survive intact, and the first save normalises whitespace and list markers before converging. Known loss (silent, inherent to Markdown): underline, text/background colour, alignment, merged cells, and text in `<angle brackets>`, which Markdown reads as an HTML tag.
- **BlockEditor** - `preset:` — `:full` (default) or `:simple`, which cuts the UI down to bold/italic/strike/code/link plus block type, with no slash menu, side menu or file panel, and takes the border and scale of a form field. The preset restricts the UI only, never the schema: an editor that could not represent something already stored would destroy it on the next save.
- **BlockEditor** - `Bali.block_editor_syntax_highlighting` (default `true`) plus a per-component `syntax_highlighting:` override. Whether `shiki` is installed is an installation-level fact, so an app decides it once in the initializer rather than at every call site — and leaving it on WITHOUT installing shiki logs an error the first time someone inserts a code block. `shiki` was always in the import graph, and it bundles every grammar it ships: on a real application, turning it off took the editor bundle from **14.3 MB to 4.0 MB** (`@shikijs/*` alone accounted for 9.08 MB, 64% of the graph).
- **FormBuilder** - `f.rich_text_group :field` and `f.block_editor_group :field` (`lib/bali/form_builder/rich_text_fields.rb`), giving the component the same ergonomics as Rails' own `rich_text_area`: the input name, the current value and the storage format are derived from the form object. `rich_text_group` defaults to the simple preset and Markdown storage. Not to be confused with the pre-existing `rich_text_area_group`, which is the ActionText/Trix helper.
- **BlockEditor** - declares the peer dependencies it actually imports. The ~35 `@tiptap/*` packages the Rich Text Editor needs existed only as a code comment that named three and trailed off in an ellipsis; `shiki`, `lowlight`, `highlight.js`, `tippy.js`, `lodash.throttle` and `@rails/request.js` were undeclared entirely. The paid `@blocknote/xl-*` packages were REMOVED from `peerDependencies` and documented separately, so nobody installs a commercial licence by reflex.
- **BlockEditor** - a component rendered while `Bali.block_editor_enabled` is false now logs a warning naming the flag, and shows a visible placeholder in development. It used to render an empty string: no markup, no error, and `assert_response :success` still passing — the most common way this component is mis-installed.
- **BlockEditor** - `--bali-block-editor-min-height` custom property, so a form can size an editor the way it sizes a textarea's `rows` instead of every instance claiming 200px.

## [v2.16.0] - 2026-07-26

### Fixed

- **SlimSelect** - the widget no longer dies (search stops filtering, clicks stop selecting, only the arrow toggles it) after a Turbo restoration visit. Turbo caches a page snapshot while controllers are still connected, so the snapshot already contained the `.ss-main` widget SlimSelect injects; on back/forward — or any navigation to an already-cached page — the controller reconnected and stacked a second, event-less widget over the dead cached one. The controller now tears SlimSelect down on `turbo:before-cache` (so the stored snapshot stays clean) and defensively removes any stale `.ss-main` before re-initializing. Only reproducible through Turbo navigation, not a hard reload — which is why it surfaced in normal app use but not in isolated page loads.
- **SlimSelect** - `include_blank` / `prompt` now render a proper SlimSelect placeholder instead of a selectable, checkmarked option. Rails emits a plain empty `<option>`; SlimSelect only treats an option as a placeholder — muted and excluded from the selectable list — when it carries `data-placeholder="true"`, so the "choose one" blank previously showed up inside the dropdown as a pickable row with a selected checkmark. `slim_select_field` now promotes the blank of a flat option list to a `data-placeholder="true"` option.

## [v2.15.0] - 2026-07-22

### Added

- **ViewSwitch** - new `Bali::ViewSwitch::Component` (#636), a DaisyUI `join` of buttons to switch between sibling views of the same content (list / table / board / schedule). Each view is a real link (`with_view(name:, icon:, href:)`); the active view (`btn-active btn-primary` + `aria-pressed`) is autodetected by matching the request path against `href` via `Bali::PathHelper#active_path?` (same logic as `Tabs::Trigger`), with an explicit `active:` override. Default look is icon + label; `icon_only: true` renders square buttons where the name becomes the native tooltip (`title`) and the accessible label (`Bali::Tooltip` wrapping was rejected: a wrapper between `.join` and `.join-item` breaks DaisyUI's border collapse between adjacent buttons). Sizes `:xs`-`:xl` (default `:sm`); per-view options passthrough supports `data: { turbo_action: 'replace' }`. Replaces the ad-hoc view toggles consuming apps keep reinventing; migrating the `DataTable::ActionsPanel` table/grid toggle to this component is a follow-up.
- **EmptyState** - new `Bali::EmptyState::Component`, the standard empty state for sections with nothing to show (#640): a centered flex-col block with an optional icon in a soft `bg-base-200` circle, a required `title:` (`text-base-content`), an optional `description:` (`text-base-content/60`) and an optional CTA via the `cta` slot (a `Bali::Link`, button or drawer trigger). `size:` controls vertical padding and icon scale — `:sm` (`py-4`, compact for cells/panels), `:md` (`py-8`, default, matches the Table empty state) and `:lg` (`py-12`, full page). Extra HTML attributes pass through to the wrapper `div`. Replaces the per-app zoo of dashed boxes and loose `<p>` tags documented in afal-apps and gobierno-corporativo.
- **IndexPage / ShowPage / DashboardPage** - new `nav` slot (`renders_one :nav`) rendered between the `PageHeader` and the body (in `DashboardPage`, before the stat cards) inside a `.page-nav` wrapper with standardized spacing (`mt-4`), for second-level navigation that pages previously had to embed in the body by hand with ad-hoc margins (#637). Documented the two-level navigation recipe (level 1 `Tabs style: :border` with icon+label, level 2 `Tabs style: :box, size: :sm`, both with `href:` tabs and the active section in the PATH so GET filter forms don't drop it) in the components guide, plus a new `IndexPage` "With nav" Lookbook preview. Pages without a `nav` slot render unchanged.

### Changed

- **Table** - the built-in empty state now renders through `Bali::EmptyState::Component` (#640), so tables and standalone empty sections look identical. API unchanged (`with_no_records_notification` / `with_no_results_notification` / `with_new_record_link` behave as before); custom notification content now sits inside the exact same centered container as the component (single source of truth via `Bali::EmptyState::Component.container_classes`). Visual nuance: the default "No records"/"No results" message is now the EmptyState title (`font-medium text-base-content`) instead of the previous muted `text-base-content/60` paragraph, and the `py-8` padding moved from the `td.empty-table` to the inner container.
- **FilterForm** - unified filter DSL (#644). `filter_attribute` is now the single declaration from which BOTH filter UIs derive: the advanced `Filters` popover (as always, via `available_attributes`) and, with `simple: true`, the inline `SimpleFilters` row (via `simple_filters_config`). New kwargs: `simple:` / `advanced:` (which UIs offer the attribute), `input:` (simple widget override, e.g. `type: :select, input: :slim_select`; validated against the widget list, invalid values raise at class-definition time), `predicate:`, `blank:`, `default:`, `icon:`, `collection:` (alias of `options:`), and `step:`/`placeholder_min:`/`placeholder_max:` for `:number_range` (previously reachable only through instance-level hashes). `options:`/`collection:`, `label:` and `blank:` also accept **zero-arity procs resolved per-instance with `instance_exec`** — inside them you can use `scope` (the relation the controller passed in, typically already narrowed to the policy scope) and per-request `I18n`, removing the two reasons apps had to bypass the class DSL (overriding `available_attributes` wholesale, or building `simple_filters:` hashes in the controller). Both escape hatches remain supported.

### Deprecated

- **FilterForm** - `simple_filter` is now a thin alias of `filter_attribute(..., simple: true, advanced: false)` and is soft-deprecated (no runtime warning; existing forms keep working unchanged and stay out of the advanced popover, exactly as before). New code should declare one `filter_attribute` per attribute. Note for exotic procs: collection procs now run under `instance_exec` (receiver = the form instance instead of the class where the lambda was defined); lambdas referencing constants/models — every known usage — are unaffected.

### Fixed

- **Selects** - long option labels no longer overlap the chevron in narrow selects on Chrome ≥ 135 (#638). DaisyUI 5.5 opts every `.select` into Chrome's customizable select (`appearance: base-select`), a mode that ignores the author's `overflow`/`text-overflow` — labels stopped truncating at the content edge and ran over the arrow painted in the padding area (most visible in the narrow field/operator selects of `Bali::Filters`, where the `truncate` class became a no-op). `bali/forms.css` now reverts `.select` to the classic rendering under `@supports (appearance: base-select)`, restoring the ellipsis before the chevron. Cost: Chrome's styled native popup (`::picker(select)`) is lost — the dropdown looks like Firefox/Safari and Chrome < 135; the visible arrow (DaisyUI `background-image`) is unchanged. Includes a regression Lookbook preview (`Form::Select` → "Narrow With Long Labels").
- **FilterForm** - `simple_filter type: :date` no longer silently discards the declared `predicate:` (#644). `simple_filter :created_at, type: :date, predicate: :gteq` — the DSL docstring's own example — used to filter by `created_at_eq`; it now honors `:gteq`. `:date_range` still has no single predicate (handled as a range). Also, unknown widget `type:` values now raise `ArgumentError` at class-definition time instead of silently rendering a plain select.
- **IndexPage** - accepts `back:` with the same contract as `ShowPage`/`FormPage` and forwards it to the `PageHeader` back button (#639). Nested listings under a resource (e.g. an initiative's approval requests) no longer need to render a `ShowPage` just to inherit the back link. Defaults to `nil` — existing index pages render unchanged.

## [v2.14.0] - 2026-07-21

### Added

- **Table** - row grouping (#621). Pass `group:` to `with_row` and `Bali::Table::Component` emits a group-header row whenever the value changes between consecutive rows, showing the group value and the count of rows in that run (e.g. `Norte (12)`). Grouping assumes caller-controlled order (the component never re-sorts), so on its own it is incompatible with user-driven column sorting and a group may continue across Pagy page boundaries (both addressed by the query-aware grouping below); rows with `group: nil` fall under a localized "Ungrouped" header (i18n `bali.table.ungrouped`). When no row is grouped the table renders exactly as before. Group headers are not sticky and never overlap `sticky_headers:`. Server-rendered markup only — no JS.
- **FilterForm / DataTable / Table** - query-aware grouping v2 (#621). `Bali::FilterForm` gains a `group_by_attribute` DSL (and `group_by_attributes:` constructor option) exposing a whitelisted top-level `group_by` param. When active, the form orders the query by the group field **first** — keeping any user column sort as the secondary sort, so grouping and sorting now coexist (sort-within-groups) — and exposes `group_counts`, the **global** per-group totals over the full filtered (unpaginated) result. The raw param can never reach `.group()`/`.order()`: `resolve_group_by` only returns a declared attribute (Ransack does not authorize `.group`). `Bali::Table` accepts `group_counts:` and shows the global total in each group header (`Norte (30)`), appending a partial hint (`Norte (30) — mostrando 25`, i18n `bali.table.group_partial`) when Pagy split the group; lookup is tolerant of string-vs-symbol keys and falls back to the page-local count. `Bali::DataTable` auto-renders an "Agrupar por" dropdown (links that merge `group_by` into the current URL, preserving filters/search/sort and resetting `page`) whenever the form declares group_by attributes, and carries an active `group_by` through the GET filter forms as a hidden field so applying filters does not drop it. `group_by` is not persisted in the filters cache (URL-only). en/es i18n included.
- **FormBuilder date fields** - date/datetime/time fields auto-fill a `placeholder:` hinting at what the field will parse, unless the caller already passed one explicitly. Derived from the effective `alt_format:` (or an i18n string for verbose formats like `F j, Y`). Part of #620.

### Changed

- **FormBuilder date fields (behavior change, #620)** - date/datetime/time fields are now **typeable by default** and display dates in a **numeric format**. Two ecosystem-wide default flips in the `datepicker` Stimulus controller: `allowInput` now defaults to `true` (the visible input accepts typed dates instead of being read-only, so flatpickr no longer sets `readonly`), and the default display `altFormat` for the date portion changed from the verbose `'F j, Y'` ("Enero 5, 2026") to numeric `'d/m/Y'` ("05/01/2026"). Time portions were already numeric and are unchanged. Combined with the auto-derived placeholder above, every date/datetime/time field now shows a `dd/mm/yyyy`-style hint by default. **Opt out per field with `allow_input: false`** to restore the read-only, pick-from-popup behavior (renders `readonly`, no placeholder). Explicit `alt_format:` and `placeholder:` still override the defaults. The controller also closes the calendar on Escape while typing — flatpickr's own `allowKeydown` gate ignores Escape when `allowInput` is on and focus is in the input, which left the calendar stuck open (and broke the drawer's Escape guard from #619). This changes the rendered display format and typing behavior of every date field across AFAL apps.

### Fixed

- **DocumentPage** - the three-panel body (TOC + content + metadata) now stacks vertically below the `lg` breakpoint instead of crushing the content column to ~1 word per line on mobile (#631). Both side panels go full-width and static (drop `sticky`) with adjusted borders; the TOC panel gets a bounded, scrollable height (`max-h-72`) so a long table of contents doesn't push content off-screen, while metadata flows full height. Content padding narrows (`px-4`) and the header toolbar wraps instead of overflowing. Pure Tailwind utility additions (`max-lg:*` + toolbar `flex-wrap`) — no JS changes, desktop (`≥lg`) layout is unchanged.
- **PageHeader** - actions bar no longer overlaps the title/subtitle at narrow viewports (<640px) on `ShowPage`, `IndexPage`, `DashboardPage`, and `DocumentPage` (#625). Regression from #507: giving the title side `flex-1 min-w-0` made it contribute zero width to the flex line, so `Level`'s `max-sm:flex-wrap` never fired. `PageHeader` now stacks its `Level` vertically on mobile (`max-sm:flex-col max-sm:items-stretch`) with both sides and the actions bar taking `max-sm:w-full`, instead of relying on wrapping. Desktop layout and the #507 long-title truncation are unchanged; `Bali::Level::BASE_CLASSES` is untouched for other consumers.
- **Drawer / Modal** - a form inside a `Bali::Drawer` no longer silently discards typed input when the user presses Escape or clicks the overlay (#619). The drawer now tracks edits and, while the form is dirty, asks for confirmation (via the DaisyUI `confirmDialog`, not `window.confirm`) before closing; a successful submit still closes without prompting. A flatpickr calendar opened inside the drawer also gets its own Escape now — the first Escape closes the calendar, the second closes the drawer. Confirm-on-close is **on by default** for `Bali::Drawer::Component` (opt out per-drawer with `dismissable_without_confirm: true`, or customize the copy with `confirm_close_message:`). `Bali::Modal::Component` gains the same guard as **opt-in** via `confirm_on_close: true` (+ optional `confirm_close_message:`); modal default behavior is unchanged. The mechanism lives in the base `ModalController` (`DrawerController` inherits it).

## [v2.13.0] - 2026-07-19

### Added

- **Status** - new `Bali::Status::Component`, a colorful SmartSuite-style status pill. Presentational and domain-agnostic: pass `options: [{value:, label:, color:}]` + `selected:`. Colors come from a fixed vibrant palette (`:slate :gray :red :orange :amber :yellow :green :teal :blue :indigo :violet :pink`) or a hex escape, rendered as inline styles (theme-independent, no Tailwind safelist). Pass `form: { url:, method:, param: }` to make it editable — click opens a portaled (`position: fixed`, escapes DataTable overflow) panel of colored option rows; selecting a row submits the form natively (respond with a Turbo Stream that replaces the wrapper). `readonly:` forces the read-only pill even when `form:` is given (permission-gated call sites), `clearable:` adds an X + a "no status" row, and `size:` is `:xs/:sm/:md`. The consumer owns the Turbo target id via `id:` passthrough.
### Security

- Bumped `loofah` 2.25.1 → 2.25.2 (resolves GHSA-5qhf-9phg-95m2, GHSA-8whx-365g-h9vv — `javascript:` URI restriction bypass — and GHSA-9wjq-cp2p-hrgf — SVG `href` local-reference bypass) and `rails-html-sanitizer` 1.7.0 → 1.7.1 (resolves GHSA-cj75-f6xr-r4g7, possible XSS). Both are transitive Rails sanitization gems; lockfile-only within existing version constraints. Surfaced by `bundler-audit` (0 open GitHub Dependabot alerts). Full test suite passes; `bundler-audit` and `yarn audit` both clean.

### Changed

- Rolled up all open Dependabot version bumps into one update. npm: `daisyui` 5.6.17 → 5.6.18. Gems (dev): `yard` 0.9.44 → 0.9.45, `simplecov` 0.22.0 → 1.0.2 (1.0 vendors its former runtime deps `docile`/`simplecov-html`/`simplecov_json_formatter`, which drop out of the lockfile). CI: `actions/setup-node` v6 → v7 across all workflows. Supersedes Dependabot PRs #615–#618.

### Fixed

- **Dev server (dummy app)** - `bin/dev` no longer dies on startup. Two bugs in `spec/dummy` broke it: (1) four `@source` directives in `app/assets/tailwind/application.css` had one extra `../` and pointed at non-existent directories, which is harmless for `tailwindcss build` but makes `--watch` fail with `ENOENT`; corrected to the real `app/{views,helpers,javascript}` and `public` paths (the dummy app's own sources are now scanned for classes too). (2) Tailwind v4's `--watch` exits when stdin closes under foreman, tearing down the whole process group — `Procfile.dev` now uses `tailwindcss:watch[always]` (`--watch=always`) so the watcher stays alive. Dev-only; no consumer-facing change.

## [v2.12.1] - 2026-07-17

### Added

- **DataTable / SimpleFilters** - `SimpleFilters::Component` now accepts `storage_id:` and `persist_enabled:`, rendering the same bookmark persistence toggle as `Bali::Filters` (wired to the `filter-persistence` Stimulus controller, which stores the user's on/off preference in `localStorage` + a `bali_persist_<storage_id>` cookie for server-side access). `DataTable#with_simple_filters` auto-populates both from the `FilterForm` (mirroring `with_filters_panel`), so screens using SimpleFilters no longer lose their filters on redirects. The toggle only renders when a `storage_id` is present; restoring filter *values* remains the consuming app's server-side responsibility. Backwards compatible.
- **Tooltip** - new `append_to:` option (default `:parent`) controls where the balloon is portaled in the DOM. Pass `:body` or a CSS-selector String to portal the balloon out of ancestors with `overflow` (wide tables in `overflow-x-auto`, cards with `overflow-hidden`) that would otherwise clip it. Balloon styling now applies via a global `bali` tippy theme (`.tippy-box[data-theme~='bali']`) so it renders correctly wherever the box is appended. Backwards compatible — the default `:parent` behavior and appearance are unchanged.

## [v2.12.0] - 2026-07-16

### Added

- **Message** - new `dismissible:` option renders an integrated close button wired to a `message` Stimulus controller; optional `dismiss_id:` persists the dismissed state in `localStorage` across reloads. Adds first-class live-region semantics via `role:` (`:alert`/`:status`/`:note`) plus `polite:`/`assertive:` sugar, rendered explicitly instead of relying on splat order. Non-dismissible messages render unchanged.
- **SideMenu** - items accept `active_when:` (String prefix, Regexp, Array, or Proc) to keep the parent item highlighted on nested full-page routes (e.g. `/departments/:id/merges/new`) without the over-matching of `match: :starts_with`. Matching logic lives in `Bali::PathHelper#active_extra_path?`; existing `match:` behavior is unchanged.
- **SideMenu** - `with_list(title:)` now accepts `badge:` and `badge_color:` to render a badge next to a section title (e.g. `Pendientes` with a `3` badge), matching the existing item-level badge contract and palette. Sections without a badge render unchanged.

### Changed

- **Docs** - documentation refresh: component counts corrected (75+ components), README categories and status table now list every component (Kanban, ConfirmDialog, DocumentEditor, DirectUpload, page templates, etc.), the components guide now documents all 74 components with per-component sections (usage example + options verified against each initialize signature), organized into categories including new Documents & Editors, Page Templates and Utilities sections, plus the Modal/Drawer turbo_stream submit pattern, the form-builder guide documents `input_name:`/`input_id:` for non-model forms, the AI dev guide catalog (.claude/CLAUDE.md) covers the full component set, and MIGRATION_STATUS.md is marked complete (historical).
- **Tooling** - slimmed the AI dev guide (`.claude/CLAUDE.md`) to point at `docs/` and `app/components/bali/` as the single source of truth for the component inventory instead of an in-file catalog that drifts out of sync; removed dead hook config (`.claude/hooks.json`, which Claude Code never reads, and a `SessionStart` hook referencing a non-existent `check-dependency-versions.sh`); fixed the `frontend-ui-ux-engineer` agent model alias. No effect on the published gem.
- Batch-bumped 5 open Dependabot PRs into one update. Gems: `propshaft` 1.3.1 → 1.3.2, `pagy` 43.4.4 → 43.6.0. npm: `daisyui` 5.6.13 → 5.6.17 (root and dummy), `@babel/preset-env` 7.29.5 → 7.29.7, `cypress` 15.18.0 → 15.18.1. Compiled CSS rebuilt against the new daisyUI.

### Security

- Bumped `view_component` 4.10.0 → 4.12.0 (resolves CVE-2026-54497 and the High-severity `around_render` HTML-safety bypass CVE-2026-54498) and `websocket-driver` 0.8.0 → 0.8.2 (resolves CVE-2026-54463/54464/54465 and the malformed Host header DoS). Lockfile-only within existing version constraints; full test suite passes.

## [v2.11.0] - 2026-07-05

### Added

- **FeedbackWidget** - `TokenGenerator`/`Component` now accept an optional `user_name:` kwarg that adds a `name` claim to the embed JWT (e.g. `"Ana López"`). Omitted entirely from the payload when not given, so existing integrations are unaffected.
- **ImageGrid** - new `empty_state` slot rendered inside a dashed-border centered box instead of the grid when there are no images — typically an "add image" action. Ignored when images are present; grids without the slot render unchanged. Adds `bali.image_grid.empty_state.*` i18n keys (en/es) used by the Lookbook preview.
- **Stepper** - steps accept a `sublabel:` option rendered as a smaller muted line under the title (event date, actor, status note), or a free content block via `with_step(title:) { ... }` for arbitrary markup. Works in both orientations; steps without sublabel render unchanged.
- **Kanban** - `Kanban::Column` accepts an optional `footer` slot rendered after the card list and outside the `SortableList`, for non-draggable per-column actions like "+ add card". Columns without a footer render unchanged.

### Changed

- Consolidated dependency refresh covering all 15 open Dependabot PRs. Gems: `tailwindcss-rails` 4.4.0 → 4.6.0, `caxlsx` 4.4.2 → 4.5.0, `sqlite3` 2.9.2 → 2.9.5, `brakeman` 8.0.4 → 8.0.5, `rrule` git `4d40a71` → `7e11c7e` (0.8.0). npm: `cypress` 15.14.2 → 15.18.0, `playwright` 1.59.1 → 1.61.1, `daisyui` 5.5.19 → 5.6.13 (root and dummy). CI: `actions/checkout` v6 → v7 across all workflows. Compiled CSS rebuilt against the new daisyUI/Tailwind.

### Fixed

- **Modal/Drawer** - the shared `submit` handler now detects `text/vnd.turbo-stream.html` responses and applies them with `Turbo.renderStreamMessage` (closing the modal/drawer on success) instead of injecting the raw `<turbo-stream>` markup as inert HTML. Enables the standard partial-update pattern (close drawer + refresh sections + toast) for forms submitted with `data-turbo="true"`; redirect and HTML-error responses behave as before.
- **DocumentEditor** - "Back to current" now restores the real document after previewing several versions in a row. `previewVersion` captured the editor state on every call, so a second preview overwrote the saved current document with the first previewed version — exiting preview then restored that version read-only, and saving in that state could overwrite the document with old content.
- **FormBuilder** - `select_group`/`select_field` and `slim_select_group`/`slim_select_field` now honor `input_name:` and `input_id:` options instead of silently dropping them, so non-model forms can namespace the rendered `<select>` under a param key (e.g. `thing[approver_id]`). Explicit `name:`/`id:` in html options still win.
- **Forms** - `.control` field wrappers now shrink inside CSS grid columns (`min-width: 0`), so a select/slim-select holding a long selected option truncates with ellipsis instead of overflowing `minmax(0, 1fr)` columns. `.ss-main` also gets a defensive `max-width: 100%`.

### Security

- Resolve all 11 open Dependabot alerts (4 high, 5 moderate, 2 low), all npm. Re-resolved transitive dependencies in `yarn.lock` (`form-data` 4.0.6, `systeminformation` 5.31.12, `tmp` 0.2.7, `js-yaml` 5.2.1, `@babel/core` 7.29.7) and `spec/dummy/yarn.lock` (`linkify-it` 5.0.2, `markdown-it` 14.3.0). Added Yarn `resolutions` for `qs` (^6.15.2) and `uuid` (^11.1.1) whose parent ranges could not reach the patched versions, and bumped the dummy app's `esbuild` to ^0.28.1. Dev/test-only surface (Cypress, eslint/standard, esbuild, BlockNote markdown chain) — no runtime gem code affected.

## [v2.10.0] - 2026-06-30

### Added

- **Confirm dialog** - Bali now replaces Turbo's native `window.confirm` with a DaisyUI-styled `<dialog>`, auto-installed via `registerAll`. It applies to every `data-turbo-confirm` (including `DeleteLink` and `ActionsDropdown` delete items), renders as real DOM in the top layer so automated browser tools (e.g. Claude in Chrome) can operate it, and supports per-trigger customization through `data-bali-confirm-{title,variant,accept,cancel}` (`variant`: `danger`/`warning`/`info`). `DeleteLink` now renders a red destructive confirm button with localized title/labels (en/es). Opt out with `window.BALI_DISABLE_CONFIRM_DIALOG`. Exports `confirmDialog` / `installConfirmDialog` for manual setup or apps that register controllers selectively. The Turbo Native `SignOut` keeps its own native confirm.

## [v2.9.3] - 2026-06-26

### Changed

- **Filters** - searchable single-select (SlimSelect) for select-type filter values, plus layout fixes that keep the value input roomy. The advanced-filter condition's single-value `select` (used for `is`/`is not` on select-type attributes) now mounts the `slim-select` controller, adding a type-to-filter search box — helpful when an attribute has many options. The SlimSelect uses the `slim-select-sm` variant so its height matches the field/operator `select-sm`. The field and operator selectors keep compact fixed widths (`sm:w-36` / `sm:w-28`) and truncate long labels with an ellipsis (e.g. "Último Inicio de Sesión", "es exactamente") instead of growing — so the value input keeps its space; both stay full-width on mobile. Both the server-rendered ERB and the JavaScript that rebuilds the value input on attribute/operator change emit equivalent markup, so dynamically added conditions get the same searchable select. The multi-select (`is any of` / `is not any of`) is unchanged. Adds a `bali.filters.search` i18n key (en/es).

### Security

- Bump `concurrent-ruby` 1.3.6 → 1.3.7 and `nokogiri` 1.19.3 → 1.19.4 (bundler-audit advisories).

## [v2.9.2] - 2026-06-19

### Fixed

- **SimpleFilters** - el buscador de texto del DataTable ahora sale del autofill de gestores de contraseñas (`autocomplete="off"` + `data-1p-ignore`/`data-lpignore`/`data-form-type="other"`). Un buscador no es un campo de credenciales, pero su `name` puede contener tokens como `name`/`email` (p. ej. `q[name_or_email_cont]` cuando se buscan esas columnas), lo que hacía que 1Password/LastPass/Dashlane ofrecieran login al enfocarlo. Aplica a todos los consumidores sin configuración.
### Changed

- **DataTable::SimpleFilters** - Filter controls now render their `label:` as a visible caption above each control (select, slim_select, toggle/radio group, number range, date). Previously `label:` was accepted in the filter config but only rendered for `:boolean` toggles (inline) and used as a `:date` placeholder fallback — for the common `select` dropdowns it was silently ignored, so a row of dropdowns all reading "All"/"Todas" gave no indication of what each one filtered. The label renders only when present (filters without `label:` are unchanged), boolean toggles keep their existing inline label (no duplicate caption), and the filter row switched from `items-center` to `items-end` so the Apply/Clear buttons and search input stay aligned with the bottom of the now taller label+control stacks.

### Fixed

- **SideMenu** - Expandable groups (`group_behavior: :expandable`) with subitems were unreachable when the sidebar was collapsed to icon-rail width. Hovering the parent icon showed only a tooltip with the parent's name; children required expanding the rail to navigate. They now open a hover/focus flyout to the right of the rail with the parent name as a title and child links beneath, mirroring the established `:dropdown` mode pattern. Hover/focus opens it; ArrowRight/Enter opens it via keyboard with arrow keys to navigate inside; Escape closes via an `is-suppressed` class cleared on the next `mouseleave`/`focusout`. On coarse pointers, first tap opens the panel without navigating so children remain reachable on touch. A 120ms intent delay throttles open, a 300ms close delay forgives cursor drift, and a 24px transparent `::before` bridge covers the gap between the narrower trigger (icon + `p-2`) and the rail's right edge so `:hover` stays continuous during traversal. The panel position is anchored by JS to the sidebar's `getBoundingClientRect().right` (via `setProperty(..., 'important')` so it wins against the CSS reset that defuses DaisyUI's CSS Anchor Positioning fallback). Children rendering is shared with `:dropdown` mode via a new `render_subitem_link` helper; `render_parent_link`, `flyout_classes`, and `render_flyout_trigger` consolidate the rest. Adds a new `SideMenuFlyoutController` Stimulus controller — registered automatically by `registerAll`
- **SideMenu** - Expandable groups (accordion variant) no longer open on mobile. The mobile-expansion override applied `display: flex !important` to every `.side-menu-expanded` element, including the `<div class="collapse side-menu-expanded">` accordion wrapper. DaisyUI's collapse relies on `display: grid` for its `grid-template-rows: max-content 0fr` → `1fr` open/close animation; the forced flex made title and content side-by-side flex items, so expandable groups appeared indented and never opened. A higher-specificity `.collapse.side-menu-expanded { display: grid !important }` restores grid

### Removed

- **SideMenu** - Drop the unused `Bali::SideMenu::Item::Component#collapse_id` method. Was defined for a checkbox-driven DaisyUI collapse pattern that never materialized in the template and used `object_id` for the id, which is non-deterministic between requests

## [v2.9.1] - 2026-05-10

### Fixed

- **SimpleFilters** - `:slim_select` filters now preserve their value after submission. The `slim_select_field` branch of the template wasn't passing `filter[:value]` (or `filter[:default]`), so the `<option>` rendered without `selected`. SlimSelect reads `option.selected` from the DOM, so the dropdown showed the placeholder text instead of the chosen option even though the URL carried the param. The `:select` branch already handled this via `options_for_select`; this brings `:slim_select` in line (#553)

## [v2.9.0] - 2026-05-10

### Changed

- **Dependencies** - Bump `cypress` 15.11.0 → 15.13.0, `playwright` 1.58.2 → 1.59.1, `@babel/preset-env` 7.29.0 → 7.29.2, and refresh transitive dependencies (`@babel/plugin-transform-modules-systemjs` 7.29.0 → 7.29.4, `lodash` 4.17.23 → 4.18.1, `flatted` 3.4.1 → 3.4.2). Bump `actions/github-script` 8 → 9 in CI workflows (#551, #536, #515, #520, #516, #537)

### Fixed

- **SlimSelect** - `slim_select_field` now accepts `content_width:` to forward SlimSelect's upstream `contentWidth` setting (`">240px"` grow-to-fit, `"<500px"` cap, `"320px"` fixed). `Bali::DataTable::SimpleFilters` defaults to `">240px"` so dropdowns with long option labels (department / job-title catalogs) grow past the trigger instead of wrapping to 2-3 lines. Also fixes `.ss-option` zero vertical padding so wrapped lines no longer merge with adjacent items, removes a legacy `.slim-select-sm .ss-search input` override that was clobbering the new search-icon padding, and scopes the inline `No Results` / `Press "Enter" to add {value}` prompt so it stops inheriting the top search bar's padding, border, and magnifier icon (#548)
- **Breadcrumb** - DaisyUI's `.breadcrumbs { padding-block: .5rem }` was beating the component's `pt-0` utility in host apps where the daisyUI plugin layer ends up after `@layer utilities` (Tailwind v4 + daisyUI plugin ordering varies per host). Move the override into the component's unlayered `index.css` so it wins regardless of layer ordering and drop the now-redundant `pt-0` utility (#530)
- **FormBuilder** - `translate_attribute` routes through `ActiveModel::Translation#human_attribute_name` so labels resolve from `activemodel.attributes.*` (form objects) as well as `activerecord.attributes.*`. Previously the `activerecord.*` namespace was hardcoded and form-object translations silently fell back to humanize (#538)
- **FormBuilder** - `select_group`, `text_area_group`, `time_zone_select_group`, and `slim_select_field` now apply DaisyUI's element-specific error classes (`select-error` / `textarea-error`) instead of always using `input-error`. Validation errors on these fields actually paint the field red now (#545)
- **FilterForm** - Default search placeholder is localized via `bali.filter_form.search_placeholder_with_fields`, and field labels resolve through `human_attribute_name`, so apps running in non-English locales no longer get a hardcoded "Search by ..." string (#539)
- Fix Ruby 4.0 warnings: parenthesize double-splat in ERB templates, silence intentional method overrides, fix indentation
- Fix pagination end alignment conflict between Rubocop and Ruby 4.0
- **SimpleFilters** - Fix `simple_filter` DSL defaulting date/date_range predicate to `:eq` instead of `nil`, causing incorrect field names (`q[created_at_eq]` instead of `q[created_at]`)
- **SideMenu** / **Topbar** - Brand row and Topbar both derive their height from the shared `--bali-chrome-height` variable (defaults to 3.5rem) so the bottom-border divider stays aligned across the seam if the value changes (#544)
- **SideMenu** - Replace `shadow-lg` on the fixed variant with a 1px right border on desktop (shadow stays on mobile overlay) — eliminates the shadow seam where sidebar meets the topbar
- **SideMenu** - `menu_switcher` dropdown now uses `<details><summary>` instead of focus-based dropdown — fixes mobile-tap reliability (focus pattern is fragile on iOS Safari)
- **SideMenu** - When sidebar is collapsed, the `menu_switcher` stays visible as an icon-only button (was hidden) with a tooltip on hover and a right-side popout for switching modules

### Added

- **ImageGrid** - New `expandable:` option on `Bali::ImageGrid::Component` and `Bali::ImageGrid::Image::Component`. When enabled, clicking an image opens it in a fullscreen lightbox with backdrop fade-in, image fade + scale-in, and a CSS spinner while the full-size image preloads. Pass `full_src:` to load a higher-resolution image; otherwise the thumbnail's `src` is reused. Closes on ESC, backdrop click, or close button; restores focus to the trigger. The grid-level `expandable:` propagates to every image but can be overridden per-image (#550)
- **AppLayout** - Auto-render a mobile-only topbar (hamburger + optional `app_name:` title) when `fixed_sidebar: true`, a sidebar is present, and no custom `topbar` slot was provided. Without this fallback the sidebar was unreachable on mobile, forcing every consuming app to copy/paste the same `lg:hidden` trigger row. Custom topbars still take precedence (#506)
- **AppLayout** - New `viewport_locked:` parameter that locks the body to 100vh and scrolls only the inner `<main>`, matching the Linear/Notion app-shell pattern. Defaults to the value of `fixed_sidebar` so existing pages keep working; pass explicitly to decouple (e.g. `fixed_sidebar: true, viewport_locked: false` for a fixed sidebar with normal page scroll)
- **SideMenu** - New `with_brand` slot for icon + text or arbitrary brand content (the existing `brand:` text param keeps working as a fallback)
- **Topbar** - New component for the top-of-content bar inside `Bali::AppLayout`'s `with_topbar` slot. Slots: `brand`, `search`, `actions` (many), `user_menu`. Built-in mobile sidebar trigger via `mobile_trigger_id:` (defaults to `SideMenu::MOBILE_TRIGGER_ID`)
- **Command** - New ⌘K-style command palette / launcher. Modal panel with search input, grouped results (`:searchable` / `:recent` / `:action` modes), keyboard navigation (↑/↓/⏎/Esc), substring highlighting, and a global ⌘K (Mac) / Ctrl+K (Windows/Linux) shortcut. Composable trigger slot, density variants (`:default` / `:compact`), and window events (`bali:command:open` / `close` / `toggle`)
- **DocumentEditor / DocumentPage** - Forward `references_url`, `references_resolve_url`, and `references_config` to the inner `BlockEditor` so the `#` entity-reference picker and entity chip icons/colors work when the editor is used via `DocumentEditor` or `DocumentPage` (#541)
- **Icon** - Numeric pixel sizes alongside the named presets: `Bali::Icon::Component.new('clapperboard', size: 24)` renders a 24×24 wrapper with a 24×24 SVG. Inline `style` + `--bali-icon-size` variable, no Tailwind safelist needed (#544)
- **Command** - i18n keys (`bali.command.placeholder`, `no_results`, `navigate`, `open_action`, `close`) are now in the en/es locale files so consumers can override / translate without monkey-patching. Inline `default:` fallbacks remain (#544)
- **SimpleFilters** - Configurable search input width via `search[:width]` option; widened defaults from `w-32 sm:w-80` to `w-48 sm:w-96`
- **SlimSelect** - Search row redesign: magnifier icon prefix, no boxed background, no input border. Selected options use blue text plus a checkmark on the right with no background tint. Trigger focus outline unchanged
- **SlimSelect** - Added 8px detached gap between input and dropdown menu for improved visual separation
- **SlimSelect** - Matched focus ring style with DaisyUI native selects (2px outline with 2px offset)
- **SlimSelect** - Added support for placing search box at the bottom when dropdown opens upwards
- **SlimSelect** - Matched native select dimensions (40px regular / 32px small) and border-radius (4px)
- **SlimSelect** - Optimized internal padding and density to match standard DaisyUI elements
- **SimpleFilters** - Enhanced configuration to support SlimSelect by default for improved usability
- **SimpleFilters** - Added `boolean` filter type: toggle switch for boolean columns (active, published, featured)
- **SimpleFilters** - Added `radio_group` filter type: single-select segmented buttons for mutually exclusive choices
- **SimpleFilters** - Added `number_range` filter type: min/max inputs for numeric columns (price, amount, quantity)

### Fixed

- **SimpleFilters** - Fix mass-assignment vulnerability by replacing blanket `permit!` with targeted parameter permitting
- **SimpleFilters** - Fix thread-safety bug: remove class-level attribute mutation from initializer that could corrupt state under concurrent requests
- **CSS** - Add DaisyUI v5 structural variable fallbacks (`--border`, `--radius-box`, etc.) so custom themes that only define colors don't silently break component borders and radii
- **Pagination** - Load Pagy 43.x `series` helper explicitly to prevent `NoMethodError` on paginated views
- **FilterForm** - Fix `simple_filters` keyword arg shadowing the instance method in `initialize`
- **Tests** - Restore corrupted `filter_form_test.rb` (82 tests were silently disabled by null-byte corruption)

## [v2.8.0] - 2026-03-23

### Added

- **Kanban** - Drag-and-drop board component composing SortableList, with Column and Card slots
- **FeedbackWidget** - Floating button with drawer for Opina feedback integration, includes JWT TokenGenerator

## [v2.7.4] - 2026-03-13

### Removed

- **SideMenu** - Removed deprecated `collapsable:` parameter and `collapsable?` alias. Use `collapsible:` instead.

## [v2.7.3] - 2026-03-11

### Changed

- **DocumentPage** - Remove internal padding from header and subheader areas; relies on app layout padding instead

## [v2.7.2] - 2026-03-11
- Bump bundler to 4.0.10 (consolidates AFAL fleet on one bundler version; see Grupo-AFAL/dev-sandbox#6)

### Added

- **DocumentEditor** - `toolbar` slot for custom content between the document title and action buttons in the app bar
- **DocumentPage** - `subheader` slot for custom content between the page header and content area

## [v2.7.1] - 2026-03-10

### Added

- **DocumentEditor** - Save status indicator showing "Saving..." / "Saved at HH:MM:SS" in the app bar
- **DocumentEditor** - Version preview loads content into the editor in read-only mode with a dismissible "Previewing Version X" banner, instead of opening raw JSON in a new tab
- **BlockEditor** - Pre-populate UserStore cache with known users before rendering comments, preventing crashes on resolved threads

### Fixed

- **BlockEditor** - Fix comment thread marks (`.bn-thread-mark`) missing highlight, cursor, and click behavior in the editor
- **BlockEditor** - Fix reply Save/Cancel buttons appearing blank in floating thread composer
- **BlockEditor** - Fix emoji reaction tooltip missing visual styles when portaled to `<body>`
- **DocumentEditor** - Auto-save now triggers correctly on content changes via `input` event delegation
- **DocumentEditor** - Version history panel redesigned with version badges, author avatars, italic summaries, and polished Preview/Restore buttons with icons
- **BlockEditor** - Fix "User resolved thread, but their data could not be found" crash by gating comments rendering on UserStore readiness
- **BlockEditor** - Fix comments sidebar losing all CSS when portaled into DocumentEditor side panel (added `bn-mantine` class to portal container)
- **BlockEditor** - Fix emoji reaction chips rendering unstyled — override Mantine CSS variables with DaisyUI-compatible colors, backgrounds, and hover states
- **BlockEditor** - Fix selected thread showing blue border on only 3 sides — use outline instead of border for consistent selection indicator
- **BlockEditor** - Fix resolved thread hover toolbar invisible due to opacity dimming the entire thread — target only comment text and header for dimming
- **BlockEditor** - Fix delete comment clearing body but not removing the thread — destroy thread when no active comments remain
- **BlockEditor** - Fix emoji picker popover rendering behind comments sidebar panel (z-index)

## [v2.7.0] - 2026-03-09

### Added

- **DocumentPage** and **DocumentEditor** components (#507)

## [v2.6.0] - 2026-03-09

### Added

- **DocumentPage** - Three-panel sticky layout (TOC | Content | Metadata) unified with DocumentEditor visual language
- **DocumentPage** - Toggle buttons in PageHeader for TOC and metadata panels
- **DocumentPage** - BlockEditor readonly support with TOC portal, plus slot-based fallback for preview/content
- **DocumentPage** - Stimulus controller (`document-page`) for panel visibility toggling
- **DocumentEditor** - `input_name` parameter and Stimulus value for configurable form field name
- **DocumentEditor** - `close_url` parameter and Stimulus value for explicit close navigation
- **DocumentEditor** - `**options` passthrough for custom HTML attributes on root element
- **SideMenu** - `bottom_group` slot for upward-expanding dropdown menus at sidebar bottom
- **AppLayout** - New layout component with flash messages, modal, and drawer infrastructure
- **AppLayout** - Login/register preview layouts and body_container presets
- **IndexPage** - Page layout component for standard list/table pages with breadcrumbs, header, and actions
- **ShowPage** - Page layout component for detail pages with optional sidebar
- **FormPage** - Page layout component for new/edit form pages with card wrapper
- **DashboardPage** - Page layout component with configurable stat cards grid
- **BlockEditor** - AI endpoint concern (`BlocknoteAi`) for proxying AI chat requests in Rails apps
- **BlockEditor** - Integration documentation for setting up AI features (`docs/blocknote-ai-rails-integration.md`)

### Fixed

- **DocumentEditor** - Replace all `innerHTML` with `createElement` + `textContent` to prevent XSS in version rendering
- **DocumentEditor** - Use Bali Dropdown component instead of raw DaisyUI HTML for export menu
- **Filters** - Fix horizontal scroll on mobile caused by DaisyUI tooltip pseudo-element on persistence button
- **SideMenu** - Force expanded sidebar view on mobile via CSS override (regardless of collapse state from localStorage)
- **SideMenu** - Hide collapse toggle on mobile, show X close button instead for fixed sidebars
- **SideMenu** - Support mobile close button for non-collapsible fixed sidebars
- **PageComponents** - Add flex-wrap to actions bar to prevent overflow on mobile
- **BlockEditor** - Prevent page scroll jump when opening AI menu via slash command or formatting toolbar on long pages

### Changed

- **Columns** - Refactored to use Tailwind flex/grid classes with responsive breakpoints, removing custom CSS
- **Dependencies** - Batch update: @babel/core, @babel/eslint-parser, @babel/preset-env, standard, daisyui, brakeman, minitest, pagy, rubocop, sqlite3, view_component; add minimatch resolution (security)
- **CI** - Bump GitHub Actions: checkout v6, setup-node v6, upload-artifact v7, github-script v8
- **Testing** - Migrated entire test suite from RSpec to Minitest (2,331 tests), aligning with AFAL handbook standards
- **Build** - Replaced Vite with esbuild (jsbundling-rails) for JavaScript bundling in dummy app
- **Security** - Added Brakeman and bundler-audit for security scanning, Dependabot configuration
- **CI** - Added security scanning workflow, updated action versions to v4 and Node 20
- **RuboCop** - Switched from rubocop-rails to rubocop-rails-omakase base configuration
- **Engine** - Added CSRF protection to `Bali::ApplicationController`

## [v2.5.0] - 2026-02-22

### Added

- **SimpleFilters** - Optional search input with `search:` parameter for quick text search
- **FilterForm** - New `simple_search_config` convenience method for SimpleFilters integration
- **PageHeader** - Default `mb-6` margin for consistent spacing

### Fixed

- **SubmitButton** - Loading spinner is now visible on form submission. Fixed two issues: `Bali::FormHelper` was not included in the dummy app (controller never connected), and DaisyUI 5's disabled button styling made the spinner invisible. The button now preserves its primary color at reduced opacity during loading.
- **Tabs::Trigger** - Now respects explicit `active:` parameter when `href` is present
- **PathHelper** - `active_path?` strips query params from both path arguments symmetrically

## [v2.4.2] - 2026-02-20

### Fixed

- **Engine** - Preview files (`preview.rb`) are now excluded from Zeitwerk autoloading, preventing `uninitialized constant` errors when eager loading is enabled in consuming apps that don't have Lookbook installed. Preview discovery by Lookbook is unaffected.

## [v2.4.1] - 2026-02-19

### Fixed

- **SideMenu::Item** - Data attributes (e.g. `data: { turbo_method: :delete }`) passed to `with_item` are now correctly forwarded to the rendered anchor tag in both expanded and collapsed states

## [v2.4.0] - 2026-02-19

### Added

- **BlockEditor** - New `comments:` option enables inline commenting via BlockNote's built-in comments extension. Supports in-memory mode (session-only, default) and REST-backed mode (`comments_url:`) for database persistence. Configure the current user with `comments_user:` and collaborators with `comments_users:` or `comments_users_url:`.

### Fixed

- **FormBuilder** - `submit_actions` button row now has consistent top margin (`mt-6`) to prevent buttons from appearing flush against the last form field
- **Modal** - Prevent modal from closing when clicking browser autocomplete options inside modal forms
- **StepNumberInput** - Guard `disconnect()` with `hasInputTarget` check to prevent error when target element is already removed from DOM ([ENJOY-KITCHEN-JS-B](https://enjoy-kitchen.sentry.io/issues/ENJOY-KITCHEN-JS-B))

## [v2.3.0] - 2026-02-18

### Added

- **SideMenu** - New `with_bottom_item` slot to pin items at the bottom of the sidebar, outside the scrollable area. Useful for user profile, logout, and account settings links. Supports multiple items and the full `Item::Component` API (icon, badge, authorized, active state, disabled, target, match type). Works in both fixed and collapsable sidebar modes.
- **BlockEditor** - New `table_of_contents:` option renders a sticky sidebar extracted from the document's heading blocks (H1–H3). Updates in real-time as headings are added or edited. Clicking any entry smooth-scrolls to that heading. Layout collapses to a vertical list on narrow viewports.

## [v2.2.0] - 2026-02-18

### Added

- **BlockEditor V2** - New rich text editor powered by BlockNote + React
  - Syntax-highlighted code blocks via Shiki
  - Multi-column layout support via `@blocknote/xl-multi-column`
  - PDF and DOCX export via `@blocknote/xl-pdf-exporter` and `@blocknote/xl-docx-exporter`
  - File upload support with Active Storage integration (images, video, audio, and general files)
  - AI assistance via `@blocknote/xl-ai` (optional, requires `ai_url` configuration)
  - **@mentions** support with configurable user search endpoint (`mentions_url`)
  - **#entity references** with per-type color differentiation (tasks, projects, documents, etc.)
    - Customizable entity type configuration via `references_config` parameter
    - Color-coded inline chips with type labels
    - Suggestion menu with grouped results, colored dots, and icon badges
    - Batch resolution of entity references on editor load
  - PDF and DOCX export support for mentions and entity references
  - Compact suggestion menu styling for better density

### Changed

- **BlockEditor** - Extracted `BlockNoteEditorWrapper` into focused modules for maintainability
- **BlockEditor** - CSS lazy-loaded only when the editor is used (no longer bundled globally)
- **Ruby 4.0 compatibility** - Replace removed `CGI.parse` with `Rack::Utils.parse_query` in `Utils::Url` and `Calendar::Header`
- **Ruby version** - Updated development Ruby version to 4.0.1

### Fixed

- **BlockEditor** - Fixed PDF export crash caused by `Infinity` value in `toggleListItem` blocks
- **BlockEditor** - Fixed PDF/DOCX export with custom inline content types (mentions, entity references)
- **BlockEditor** - Fixed table cell structure handling in entity reference batch resolution
- **BlockEditor** - Resolved relative URLs for images in PDF/DOCX export
- **BlockEditor** - Improved code block and link styling
- **BlockEditor** - Removed client-side file type restriction for uploads
- **BlockEditor** - Added video, audio, and SVG MIME types to upload allowlist
- **BlockEditor** - Increased default max upload size from 10MB to 50MB for video/audio support
- **BlockEditor** - Upload errors now show descriptive toast messages instead of generic failure
- **lefthook-linux-arm64** - Moved to `optionalDependencies` to prevent CI failures on x64 runners

## [v2.1.1] - 2026-02-12

### Added

- **Costa Norte Theme** - Custom DaisyUI 5 theme for Costa Norte brand (teal/gold palette)
  - Opt-in CSS file at `css/themes/costa-norte.css` with all 18 DaisyUI color variables in OKLCH
  - npm package export `./css/themes/*.css` for consumer apps
  - Lookbook theme sampler preview and dedicated layout
  - Usage documentation in `docs/guides/custom-themes.md`
- **Navbar Burger** - Allow burger to render as a link when `href` is provided
  - Renders an `<a>` tag instead of a `<button>` for navigation use cases

### Changed

- **Navbar** - Allow custom background colors via `color: nil` with `class:` option
  - Pass `color: nil` to skip preset color classes, then provide custom classes via `class:`
  - Example: `Bali::Navbar::Component.new(color: nil, class: 'bg-indigo-600 text-white')`
- **FormBuilder** - Replace `class_names` with `token_list` in step number fields

### Fixed

- **SideMenu + Navbar** - Fixed mobile sidebar toggle from Navbar hamburger
  - SideMenu Stimulus controller was scoped to its own element, unreachable from Navbar burger
  - Overlay referenced a non-existent checkbox ID for non-collapsable fixed menus
  - Introduced checkbox+label pattern (matching DaisyUI drawer convention) for cross-component toggling
  - Added `type: :sidebar` burger variant that renders a `<label>` targeting the mobile trigger checkbox
  - Added global window events (`bali:side-menu:toggle`, `bali:side-menu:open`, `bali:side-menu:close`) for programmatic control
  - Added `mobile_trigger_id` parameter to SideMenu for custom checkbox IDs
  - Backwards compatible: existing `is-active` class approach still works
- **SubmitButton** - Use a spinner `<span>` element instead of adding loading classes directly to the button, avoiding style conflicts
- **FormBuilder RadioFields** - Fix data attribute merging to properly support both shared and per-item data attributes
- **Utils** - Add nil-safety to `conditional_classes` when no conditional names are passed

### Chores

- Add dangerous command deny list to `.claude/settings.json`
- Add CLAUDE.md context files for components, views, config directories

## [v2.1.0] - 2026-02-04

### Added

- **DataTable SimpleFilters** - New lightweight inline filter UI for CRUD views
  - Alternative to complex Filters component for simple filtering needs
  - Renders inline select dropdowns without AND/OR groupings, popovers, or badges
  - Auto-configures from FilterForm via `with_simple_filters` slot
  - New `SimpleFiltersConfiguration` concern for FilterForm DSL support
  - Supports instance-level configuration via `simple_filters:` parameter
  - Includes `simple_filters_config`, `simple_filters_enabled?`, `simple_filters_active?` methods

- **PaginationFooter Component** - Standardized pagination footer with summary and controls
  - Combines summary text (e.g., "Showing 1-10 of 100 items") with pagination controls
  - Summary on left, pagination buttons on right
  - Supports custom `item_name`, `show_summary`, and `show_pagination` options
  - Auto-hides pagination when only one page exists

- **Columns Component** - Added Bulma-compatible column system with Tailwind implementation
  - Tailwind display utilities support on Column component
- **Filters Component** - Added preserved query params support for maintaining URL state
- **Filters Component** - Added turbo_stream support and refactored controller submission logic
- **FilterForm** - Made `ransack_params` public for component access
- **SideMenu Component** - Added `target` and `rel` attributes support for menu items

### Changed

- **ImageField Component** - Render input using `raw_file_field` to bypass custom form builder wrappers
- **ImageField Component** - Wrap icon in span and remove `text-base-content` class from icon styling

### Fixed

- **Drawer & Modal Components** - Adjusted z-index values and positioning to improve layering behavior
- **SlimSelect** - Fixed `slim_select_field` to deep merge data attributes instead of overwriting

### Dependencies

- **ViewComponent** - Upgraded from 3.x to 4.2.0
  - Updated preview configuration: `config.view_component.preview_paths` → `config.view_component.previews.paths`

- **Pagy** - Upgraded from 8.x to 43.2.8 (major API redesign)
  - `Pagy::Backend`/`Pagy::Frontend` modules → `Pagy::Method`
  - `Pagy.new()` → `Pagy::Offset.new()`
  - `items:` parameter → `limit:`
  - `pagy.prev` → `pagy.previous`
  - `Pagy::DEFAULT` → `Pagy::OPTIONS`
  - Added fallback URL builder for contexts without request object (e.g., Lookbook previews)
  - Updated `Pagination::Component` and `DataTable` previews for new API

## [v2.0.5] - 2026-02-03

### Added

- **Form::Errors Component** - New component for displaying form validation error summaries
  - Renders error list using `Bali::Message::Component` with error styling
  - Only renders when model has errors (`render?` returns false otherwise)
  - Supports optional `title` parameter for custom header text
  - FormBuilder integration via `f.error_summary` helper method

- **DirectUpload Component** - Auto-clear files on successful Turbo form submission
  - Listens for `turbo:submit-end` event on parent form
  - Clears file list when `event.detail.success` is true (2xx response)
  - Files remain on failed submissions so users can retry

### Fixed

- **DirectUpload Component** - Fixed field name generation when using `form_with url:` without a model
  - Previously generated `[method][]` instead of `method[]` when `form.object_name` was empty
  - Now correctly handles empty object names for both single and multiple file modes

### Changed

- **Release Skill** - Rewritten with two-phase PR workflow
  - Phase 1: Creates release prep PR with changelog updates for review
  - Phase 2: After merge, bumps version, tags, and publishes GitHub release
  - New `--continue` flag to run Phase 2 after PR is merged
  - State persistence via `.release-pending.json` between phases

## [2.0.4] - 2026-01-30

### Added

- **Link Component** - Dynamic size support for Modal and Drawer
  - New nested options syntax: `modal: { size: :lg }` and `drawer: { size: :lg }`
  - Backward compatible: `modal: true` and `drawer: true` still work with default sizes

### Changed

- **Drawer Component** - Standardized size names to match other Bali components
  - `narrow` → `sm`
  - `medium` → `md` (default)
  - `wide` → `lg`
  - `extra_wide` → `xl`
  - Added `full` size option

## [2.0.3] - 2026-01-30

### Changed

- **JavaScript Imports** - Redesigned import strategy for standard npm package usage
  - Converted all internal `bali/...` imports to relative paths
  - Added `exports` field to package.json for proper module resolution
  - Consuming apps no longer need complex bundler alias configuration
  - Import from `'bali-view-components'` instead of internal paths

## [2.0.2] - 2026-01-28

### Added

- **Link Component** - Added `soft` and `outline` styles to `Bali::Link::Component`
- **Message Component** - Added style variants (`soft`, `outline`, `dash`) to `Bali::Message::Component`
- **Notification Component** - Added `style` options and updated tag's rounded class
- **Tag Component** - Added a new preview page showcasing all variations and combinations
- **SlimSelect** - Added `results_text` support and `resultsText` option for grouping AJAX results
- **Utility** - Added `.box` utility class
- **Translations** - Added "results" translation key for select menu in English and Spanish

### Changed

- **Drawer Component** - Refactored overlay visibility and z-index
- **Tag Component** - Made `text` attribute optional, falling back to content
- **Dropdown Component** - Render dropdown menu items as plain links
- **Internal** - Relocated component-specific CSS variables to `bali-` prefixed variables and updated `build_url` calls


## [2.0.1] - 2026-01-27

### Changed

- **Filters Component** - Consolidated `AdvancedFilters` and `Filters` into a single unified `Filters` component
  - Removed separate `AdvancedFilters` component (functionality merged into `Filters`)
  - Added search input with clear button (x) for easy clearing of persisted search
  - Improved filter persistence handling with `clear_search` parameter

### Fixed

- **FilterForm** - Refactored into focused concerns for better maintainability
  - Extracted `SearchConfiguration` concern for search DSL and methods
  - Extracted `FilterGroupParser` concern for Ransack grouping parsing
  - Fixed search persistence bug where clearing search text didn't clear persisted value

### Dependencies

- Added `lucide-rails` as runtime dependency for icon rendering
- Updated `@source` directive documentation for Tailwind v4 configuration

## [2.0.0] - 2026-01-26 - Tailwind + DaisyUI Migration

**This is a major release migrating all 60+ components from Bulma CSS to Tailwind + DaisyUI 5.**

### Infrastructure

- Added Tailwind CSS build step to CI pipeline for proper asset compilation

### Breaking Changes

- **`Bali::Link::Component`** - `type:` parameter deprecated. Use `variant:` instead.
  - Added backwards compatibility: passing `type:` still works but logs deprecation
  - New `variant:` supports: `:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost`, `:link`, `:neutral`
  - New `size:` parameter: `:xs`, `:sm`, `:md`, `:lg`, `:xl`
  - New `plain:` parameter for links without button styling
  - New `authorized:` parameter for permission-based rendering

  ```ruby
  # Before
  render Bali::Link::Component.new(href: '/users', name: 'Users', type: :primary)

  # After
  render Bali::Link::Component.new(href: '/users', name: 'Users', variant: :primary)
  ```

- **`Bali::Card::Component`** - `footer_items` slot removed. Use `actions` slot instead.
  - New slot structure: `header`, `title`, `image`, `actions`
  - Actions render inside `card-actions` container with proper DaisyUI styling

  ```ruby
  # Before
  render Bali::Card::Component.new do |c|
    c.with_footer_item { render Bali::Button::Component.new(name: 'Save') }
  end

  # After
  render Bali::Card::Component.new do |c|
    c.with_action { render Bali::Button::Component.new(name: 'Save') }
  end
  ```

- **`Bali::Filters::Component`** - Consolidated filter component (replaces old Filters and AdvancedFilters)
  - Multiple filter groups with AND/OR combinators between groups
  - Multiple conditions within each group with AND/OR combinators
  - Type-specific operators for text, number, date, select, and boolean fields

- **`Bali::Breadcrumb::Item::Component`** - `href` is now optional (was required).
  - Items without `href` are automatically marked as active
  - Parameter order changed: `name:` is now the primary parameter
  - Links only show underline on hover (not by default)
  - Active items render as non-clickable `<span>` elements with `cursor-default`
  - Removed legacy BEM classes (`breadcrumb-component`, `breadcrumb-item-component`)
  - Added `aria-current="page"` to active items for accessibility

  ```ruby
  # Before
  c.with_item(href: '/page', name: 'Current', active: true)

  # After (simplified - no href means auto-active)
  c.with_item(name: 'Current')
  ```

- **`Bali::Tag::Component`** - `tag_class:` parameter deprecated. Use `color:` instead.

- **`Bali::Calendar::Component`** - `all_week:` parameter deprecated. Use `weekdays_only:` instead.

- **CSS Class Changes** - All Bulma classes replaced with DaisyUI equivalents:
  - `is-primary` → `btn-primary`, `badge-primary`, etc.
  - `is-danger` → `*-error` (DaisyUI uses "error" not "danger")
  - `is-small/medium/large` → `*-sm/md/lg`
  - `columns` → `grid grid-cols-*`
  - `card-content` → `card-body`
  - `notification` → `alert`
  - See `docs/migration/BREAKING_CHANGES.md` for complete mapping

### Added

- **`Bali::FilterForm`** - Enhanced filter form with Ransack groupings support
  - Dynamic add/remove for both conditions and groups
  - Pre-populated filters from URL params
  - Quick search integration and reset functionality
  - Date range "between" operator uses Flatpickr range mode
  - Locale-aware date formats: `M j, Y` for English, `j M Y` for Spanish

- **`Bali::Button::Component`** - Proper ViewComponent (was previously a helper)
  - Full DaisyUI button support with variants, sizes, states
  - Loading state with spinner
  - Icon support (left and right)
  - Disabled state

- **`Bali::Avatar::Group::Component`** - Display grouped avatars with overlap styling
- **`Bali::Avatar::Upload::Component`** - Avatar with upload/edit functionality

- **`Bali::Card::Action::Component`** - Card action button/link for footer actions

- **`Bali::DataTable::ColumnSelector::Component`** - Toggle table column visibility
  - Supports hiding columns by default
  - Works by column index, no coordination needed between selector and table cells

- **`Bali::DataTable::Export::Component`** - Export data table to various formats

- **`Bali::DirectUpload::Component`** - Direct file upload with progress indication

- **`Bali::Modal::Header::Component`** - Modal header slot component
- **`Bali::Modal::Body::Component`** - Modal body slot component
- **`Bali::Modal::Actions::Component`** - Modal actions/footer slot component

- **`Bali::Pagination::Component`** - Standalone pagination component using Pagy

- **Icon System Overhaul** - New Lucide-based icon resolution pipeline
  - 1,600+ Lucide icons available directly
  - Backwards compatible: old Bali icon names still work (mapped to Lucide equivalents)
  - Kept icons: brand logos (Visa, Mastercard, PayPal), social (WhatsApp, Facebook), regional (flags)
  - Custom icons: app-specific via `Bali.custom_icons`
  - New `size:` parameter: `:small`, `:medium`, `:large`

- **Stimulus Controllers**
  - `advanced-filters` - Main filter UI controller
  - `filter-group` - Filter group management
  - `condition` - Individual condition management
  - `column-selector` - Table column visibility toggle

- **Dependencies**
  - Added `pagy` gem (~> 8.0) for pagination
  - Added `lucide-rails` gem for Lucide icon integration

### Changed

- **All 60+ Components** - Migrated from Bulma SCSS to Tailwind + DaisyUI 5
  - Removed all `.scss` files, using `.css` with `@apply` or inline Tailwind classes
  - Components now use DaisyUI semantic classes (`btn`, `card`, `modal`, etc.)
  - Responsive design using Tailwind breakpoints

- **`Bali::Calendar::Component`** - Refactored with improved API (backward compatible)
  - `start_date` now accepts `Date` objects directly (strings still work)
  - New `weekdays_only:` parameter replaces confusing `all_week:` (deprecated but still works)
  - Extracted `EventGrouper` class for cleaner event grouping logic
  - Added helper methods: `month_view?`, `week_view?`, `show_weekends?`, `weekdays_only?`
  - Preview consolidated from 7 methods to 3 with `@param` annotations
  - Added 14 new tests (33 total)

- **`Bali::DataTable::Component`** - Uses consolidated `Filters` component with Ransack groupings support
  - New `filters_panel` slot accepts `available_attributes:` for defining filterable fields
  - New `toolbar_buttons` slot for right-aligned buttons (column selector, export, etc.)
  - Added sorting examples using Ransack's `sort_link` helper
  - Added pagination examples using Pagy

- **`Bali::Modal::Component`** - New slot-based API
  - Uses native `<dialog>` element with DaisyUI modal styling
  - New slots: `header`, `body`, `actions`
  - Backdrop click to close
  - Escape key to close

- **`Bali::Dropdown::Component`** - Migrated to DaisyUI dropdown
  - Uses `dropdown`, `dropdown-content`, `menu` classes
  - Supports positioning: `dropdown-end`, `dropdown-top`, `dropdown-left`, `dropdown-right`

- **`Bali::Table::Component`** - Migrated to DaisyUI table
  - Uses `table`, `table-zebra`, `table-pin-rows`, `table-pin-cols` classes
  - Sticky headers supported via `table-pin-rows`

- **`Bali::Tabs::Component`** - Migrated to DaisyUI tabs
  - Uses `tabs`, `tabs-box`, `tab`, `tab-active` classes

- **`Bali::Tooltip::Component`** - Migrated to DaisyUI tooltip
  - Uses `tooltip`, `tooltip-*` positioning classes
  - Removed Tippy.js dependency for simple tooltips

- **`Bali::Timeline::Component`** - Migrated to DaisyUI timeline
  - Uses `timeline`, `timeline-start`, `timeline-middle`, `timeline-end` classes

- **`Bali::Stepper::Component`** - Migrated to DaisyUI steps
  - Uses `steps`, `step`, `step-primary/secondary/etc` classes

- **`Bali::Progress::Component`** - Migrated to DaisyUI progress
  - Uses `progress`, `progress-primary/secondary/etc` classes

- **`Bali::Notification::Component`** - Migrated to DaisyUI alert
  - Uses `alert`, `alert-info/success/warning/error` classes

- **`Bali::Loader::Component`** - Migrated to DaisyUI loading
  - Uses `loading`, `loading-spinner/dots/ring/ball/bars/infinity` classes

- **`Bali::SideMenu::Component`** - Migrated to DaisyUI menu
  - Uses `menu`, `menu-title`, DaisyUI collapse for nested items
  - Improved collapsed state with tooltips

- **Form Components** - All 27+ form field components migrated
  - Inputs use `input`, `input-bordered`, `input-*` classes
  - Selects use `select`, `select-bordered` classes
  - Checkboxes use `checkbox`, `checkbox-*` classes
  - File inputs use `file-input`, `file-input-bordered` classes

### Removed

- **SCSS Files** - All component `.scss` files removed (replaced with `.css` or inline Tailwind)
- **Bulma Dependencies** - No longer requires Bulma CSS framework
- **`Bali::Card::FooterItem::Component`** - Removed, use `actions` slot instead

### Migration Guide

See `docs/migration/BREAKING_CHANGES.md` for:
- Complete Bulma → DaisyUI class mapping table
- Per-component migration examples
- Step-by-step upgrade instructions

## [1.4.23] - 2025-12-12

### Changed

- `Bali::SideMenu::Item::Component` to display a tooltip when the menu is collapsed.

## [1.4.22] - 2025-12-12

### Changed

- Update filter form submission to prevent default behavior, update URL, and enable custom search input button options.

## [1.4.21] - 2025-11-28

### Added

- `Bali::DataTable::Action::Component` to encapsulate action rendering with optional description tooltips.

### Changed

- `Bali::DataTable::ActionsPanel::Component` now uses `Bali::DataTable::Action::Component` for rendering actions, enabling support for action descriptions via tooltips.

## [1.4.20] - 2025-11-27

### Added

- `Rrule::EnglishHumanizer` service to convert RRule objects to human-readable English text.
- `Rrule::SpanishHumanizer` service to convert RRule objects to human-readable Spanish text.
- `Bali::Concerns::GlobalIdAccessors` concern to define GlobalID getter and setter methods for ActiveRecord associations.
- `rrule` gem dependency for recurrence rule handling.

### Changed

- Updated `Bali::RecurrentEventRuleForm::Component` to display humanized recurrence rules in English and Spanish.
- Added RRule override to support `humanize` method with locale parameter.

## [1.4.19] - 2025-11-25

### Added

- `is-borderless` class support to `Bali::List::Component` to remove the border styling.

## [1.4.18] - 2025-11-18

### Changed

- Add more space between collection filters with multiple options and few options

## [1.4.17] - 2025-10-28

### Changed

- Allow `Bali::DataTable::ActionsPanel::Component` to render custom actions.

### Fixed

- Avoid non query param conversion to array when adding new ones to a url.

## [1.4.16] - 2025-10-28

### Changed

- Allow `Bali::Filters::Component` to receive options such as data.

## [1.4.15] - 2025-10-27

### Added

- `authorized?` method to `Bali::Link::Component` and `Bali::DeleteLinkComponent`
- `items` slot to `Bali::ActionsDropdown` component.

### Changed

- Use `Bali::Link::Component` for `items` slot instead of `Bali::Dropdown::Item::Component` in `Bali::Dropdown::Component`

## [1.4.14] - 2025-10-22

### Added

- `grid`, `list` icons.
- `Bali::DataTable::ActionsPanel::Component` component.

## [1.4.13] - 2025-09-24

### Added

- `checkbox-reveal-controller.js` stimulus controller.
- `Bali::Image::Component` component. This component renders an image and allow to render an input to change and clear the image

## [1.4.12] - 2025-09-24

### Fixed

- maintain collapsed side menu after redirections

## [1.4.11] - 2025-09-23

### Added

- `menu_switches` slot to `Bali::SideMenu::Component`.
- `collapsable` attribute to `Bali::SideMenu::Component`.

## [1.4.10] - 2025-09-12

### Added

- `after-change-fetch-url-value` to `slim-select-controller.js`. When this value is present the controller will peform a fetch request after the value of the select has changed.

## [1.4.9] - 2025-09-09

### Changed

- `Bali::Filters::Component` to render the right input for each `ransack` predicate.

## [1.4.8] - 2025-09-04

### Changed

- `time_period_select_field` and `time_period_select_field_group` to `Bali::FormBuilder`
- `Bali::TimePeriods::SelectOptions` as default time periods for `time_period_select_*` fields.

## [1.4.7] - 2025-08-29

### Changed

- `Bali::RecurrentEventRuleForm` component.
- `recurrent_event_rule_field` and `recurrent_event_rule_field_group` to `Bali::FormBuilder`

## [1.4.6] - 2025-07-28

### Changed

- `submit` function of `ModalController` to check and report inputs validity

## [1.4.5] - 2025-07-29

### Changed

- Upgrade `gems` and `importmap`
- Replace `code climate` with `qlty`

## [1.4.4] - 2025-06-11

### Changed

- `datepicker-controller` and `date fields` to support disabling specific dates.

## [1.4.3] - 2025-05-29

### Changed

- `slim-select` to support rendering custom HTML for remote search results.

## [1.4.2] - 2025-04-23

### Changed

- `Bali::SideMenu::Component` component to preserve scroll position when a link has been clicked

- `Bali::SideMenu::Item::Component` component to add `is-list` class when items are present.

## [1.4.1] - 2025-03-27

### Changed

- `Table` component to allow bulk actions to render a modal and add custom style

## [1.4.0] - 2024-02-20

### Updated

- Upgrade `rails` to version `8.0.1`
- Upgrade `ruby` to version `3.3.7`
- Updated `gems` and importmap

## [1.3.3] - 2024-02-25

### Fixed

- value was displayed as `undefined` when adding a suffix or prefix in a pie or doughnut chart.

## [1.3.2] - 2024-01-30

### Fixed

- Redirection issues when attempting to open a restricted modal.

## [1.3.1] - 2024-12-20

### Changed

- Set `modal` attribute to `false` when link is disabled (`Bali::Link::Component`)

## [1.3.0] - 2024-10-18

### Changed

- Upgrade to `rails` to `7.2`
- Update `gems` and `importmap`

## [1.2.5] - 2024-09-17

### Changed

- Added `submit-actions` class name to `submit_actions` fields helper.

## [1.2.4] - 2024-07-25

### Changed

- Updated `rails` to version `7.1.4`

## [1.2.3] - 2024-07-25

### Changed

- Updated gems and npm packages

## [1.2.2] - 2024-06-06

### Fixed

- Cannot read properties of undefined (reading 'destroy') in `stimulus` controllers.
- Missing target element "menu" for "navbar" controller

## [1.2.1] - 2024-05-20

### Fixed

- Incorrect `for` attribute value in radio buttons of `radio_buttons_field_group` when value is a datetime

## [1.2.0] - 2024-05-06

### Changed

- import `GoogleMapsLoader` dynamically
- import `tippy` dynamically
- import `Sortable` dynamically
- import `Chart` dynamically
- import `MarkerClusterer` dynamically
- import `createPopper` dynamically

## [1.1.1] - 2024-05-09

### Fixed

- imports with relative paths were failing in `js` files.

## [1.1.0] - 2024-03-08

### Added

- Button to clear polygons in coordinates polygon field
- Button to clear holes in coordinates polygon field

## [1.0.0] - 2024-04-17

### Changed

- Migrated from `jsbundling-rails` to `importmaps-rails`

## [0.76.0] - 2024-04-17

### Added

- Updated `gems` and `npm` packages

## [0.75.0] - 2024-02-28

### Added

- `Bali::Commands::XlsxExport` class. This class allows us to use DSL in xlsx export.

## [0.74.1] - 2024-02-19

### Fixed

- Fix InputOnChangeController#change. Updated to use the new Slim Select 2.0 API.

## [0.74.0] - 2024-02-15

### Changed

- Allow `DrawingMapsController` to draw and export multiple polygons classified into shells and holes. As a result, the value from `coordinates_field` and `coordinated_field_group` has changed from `[{ lat: , lng:}]` to `{ shells: [{ lat: , lng:}], holes: [{ lat: , lng:}] }`. This format `[{ lat: , lng:}]` is still working to initilize the polygons within the map, but changes in the map will be store using the new format.

## [0.73.0] - 2024-01-31

### Fixed

- Slim select does not render

## [0.73.0] - 2024-01-30

### Changed

- Updated gems and npm packages

## [0.72.0] - 2024-01-26

### Added

- `Bali::Commands::CsvExport` class. This class allows us to use DSL in csv export.

## [0.71.1] - 2024-01-22

### Fixed

- Use `as` attribute of `form_for` in the `id` of the radio buttons when using `radio_buttons_group`

## [0.71.0] - 2023-11-28

### Added

- `Bali::BulkActions::Component` component. This component enables you to double-click on multiple DOM elements, selecting them, and subsequently applying an action.

## [0.70.0] - 2023-10-06

### Added

- `Cards` to `LocationsMap::Component`. These cards help to display detailed information for each marker. When a marker is clicked on, all cards matching the latitude and longitude of the marker will have the `is-selected` class added to them.

## [0.69.0] - 2023-09-19

### Changed

- Unify the data structure of the `Chart` component and `Chart.js`.

## [0.68.1] - 2023-09-19

### Fixed

- `name` attribute of the html `label` element of `switch_field_group`.

## [0.68.0] - 2023-09-19

### Added

- Add `display_percent` option on `Chart::Component` for automatically calculating and displaying percentages on the tooltip

## [0.67.3] - 2023-08-23

### Added

- `youtube` icon
- `title` to `mexican flag` icon
- `title` to `usa flag` icon
- `title` to `shopping cart` icon

### Changed

- color of the `facebook` and `instagram` icons to `currentColor`

### Changed

- `facebook` and `instagram` icons to fill with the current color.

## [0.67.2] - 2023-08-23

### Added

- `.is-margin-auto` CSS style
- `.is-circle` CSS style
- `.is-unclosable` CSS stlye to notification component. This css style hides the button to close the notification
- `icon_tag` helper method
- `Bali::TenancyTestsHelper`
- `Bali::TestsHelper`
- `Bali::Concerns::Mailers::RecipientsSanitizer`. This concern includes `send_mail` method, which removes inactive emails before sending mail.
- `Bali::Concerns::Mailers::UtmParams`
- `Bali::FlashNotifications::Component`

## [0.67.1] - 2023-08-15

### Changed

- Add CSS classes for different widths for select fields

## [0.67.0] - 2023-08-11

### Added

- Add ability to add custom filters on the Filters::Component
- Create `Bali::Types::DateRangeValue` to support :date_range type in `attribute` method

## [0.66.3] - 2023-08-08

### Added

- Custom class in the `currency_field_group` label when it renders a tooltip.

### Fixed

- Issue when an input field has an add-on and error

## [0.66.2] - 2023-07-18

### Added

- `Bali::Concerns::SoftDelete`
- `Bali::Concerns::Controllers::DeviceConcern`
- `GeocodeAdddressController` (javascript)
- `ios_naitve_app_user_agent` and `android_native_app_user_agent` as `Bali` configuration

## [0.66.1] - 2023-07-12

### Fixed

- Skip rendering for `ActionsDropdown::Component` when no content is present

## [0.66.0] - 2023-06-16

### Added

- Add `allow_input` to datepicker to be able to manually enter a date

## [0.65.1] - 2023-06-13

### Changed

- Relax ruby dependency to allow greater than `3.2`
- Update `library_version.thor` script to autodetect current version and increment it.
- Update Library authors

## [0.65.0] - 2023-06-07

### Changed

- Allow to add attributs to the FilterForm where only 1 value can be selected

### Fixed

- `TableController` check for elements presence before updating.

## [0.64.0] - 2023-06-05

### Added

- Add ability to add bulk actions to a `Table::Component`

## [0.63.0] - 2023-06-01

### Added

- Allow to persist the `FilterForm` filters across requests

## [0.62.0] - 2023-05-25

### Added

- Allow `slim_select_field` to autocomplete options from the server.

## [0.61.8] - 2023-05-23

### Changed

- Allow to add custom data attributes to `add/subtract` buttons in the step number field.

## [0.61.7] - 2023-05-14

### Fixed

- Pass the correct `route_path` argument instead of `route_name` to `Calendar::Header`

## [0.61.6] - 2023-04-18

### Changed

- Allows adding `custom icons` from the host application to the `Bali::Icon::Component`.

## [0.61.5] - 2023-03-31

### Added

- `Bali::Concerns::DateRangeAttribute` concern. This concern allows to define date range attributes, for example, `date_range_attribute :date_range, default: Time.zone.now.all_day`
- `max_date` option to `date_field_group` and `date_field`. you to set a maximum date that can be selected

## [0.61.4] - 2023-03-30

### Changed

- Renamed `route_name` to `route_path` in `Calendar` component. `route_path` expects a string, for example, `/lookbook`.

## [0.61.3] - 2023-03-26

### Fixed

- Fix `ransack` deprecation warning by avoiding passing a nil value to the `sort_link` method.

## [0.61.2] - 2023-03-14

### Added

- Add prefix and suffix to axis labels (`Chart` component)
- Prevent the tooltip title from being truncated (`Chart` component)
- Add prefix and suffix to tooltip label (`Chart` component)

## [0.61.1] - 2023-03-14

### Fixed

- Allow `TimeValue` to receive date string without seconds

## [0.61.0] - 2023-03-13

### Added

- Add `Message::Component`

### Changed

- Upgrade Gems

## [0.60.0] - 2023-03-13

### Changed

- `TimeValue`now returns a `Time` object when retrieved from DB to be able to format it.
- `time_field_group` is updated to handle a `Time` value instead of a `String`

## [0.59.2] - 2023-03-10

### Added

- Added sticky headers for table component.

## [0.59.1] - 2023-03-11

### Fixed

- Correctly scope the previous `ActionsDropddown::Component` css change.

## [0.59.0] - 2023-03-11

### Added

- Added a `readonly` option for the `Rate::Component` for display only purposes.

### Changed

- Add bottom-margin to `ActionsDropddown::Component` when placed inside a `.buttons` element to align with other buttons.

## [0.58.2] - 2023-02-20

### Changed

- Allow to override the `submit-on-change` `method` and `action` values throught the StimulusJS controller

## [0.58.1] - 2023-02-15

### Changed

- Ability to add multiple actions in a `List::Item::Component`
- Ability to add content in the middle of a `List::Item`

## [0.58.0] - 2023-02-11

### Changed

- Add ability to manage multiple files in a File Input

## [0.57.1] - 2023-02-02

### Added

- `@tiptap/pm` to `package.json` as `dependency`

### Fixed

- `Module not found` error when compiling assets in host application.

## [0.57.0] - 2023-01-31

### Fixed

- Added `Bali::Concerns::NumericAttributesWithCommas`. This concern complements the `percentage_field_group` and `currency_field_group` methods by removing the `commas` before saving the value to the DB.

## [0.56.3] - 2023-01-29

### Fixed

- Perform `Filters::Component` request with a `turbo_stream` format

## [0.56.2] - 2022-12-22

### Added

- Add `question-circle` icon

## [0.56.1] - 2022-12-20

### Added

- Add ability to specify a `submitter` on the `SubmitOnChange` controller in order to specify a different formaction and formmethod

## [0.56.0] - 2022-12-16

### Added

- Dispatch the `modal:success` event when the form is successfully submitted.

## [0.52.7] - 2022-12-06

### Added

- Allow to specity vertical alignment as a param for `Level::Component`

## [0.52.6] - 2022-12-02

### Changed

- Align file field ergonomics with other form inputs

## [0.52.5] - 2022-12-02

### Added

- Display all files selected in `file-input`

## [0.52.4] - 2022-12-02

### Fixed

- Fix `radio_field_group` display when it has an error.

## [0.52.3] - 2022-11-30

### Added

- Add `disabled` support for `Link::Component`

## [0.55.2] - 2022-11-30

### Added

- Add ability to display an icon in the trigger of the reveal component.

## [0.55.1] - 2022-11-16

### Added

- Add ability to hide `Table::Component` th

## [0.55.0] - 2022-11-16

### Added

- `Page Hyperlinks` to `Rich Text Editor`.

## [0.54.3] - 2022-11-15

### Added

- Add option to pass a container class to the `Navbar::Component`

## [0.54.2] - 2022-11-14

### Added

- `additional query params` to filters component. This helps to add query parameters not related to the form.

## [0.54.1] - 2022-11-11

### Updated

- Add a parameter to the `datepicker controller` to decide whether or not the alt input should be rendered.

## [0.54.0] - 2022-11-08

### Added

- Create `RichTextEditor::Component`

## [0.53.3] - 2022-10-21

### Added

- `wallet`, `wallet-alt`, `oxxo` icons.

## [0.53.2] - 2022-10-19

### Added

- Add option to specify a tooltip for a form label

## [0.53.1] - 2022-10-18

### Added

- Add `modal.fullwidth` class for full width modals
- Allow multiple CSS classes for the modal wrapper

## [0.53.0] - 2022-10-18

### Added

- Add `sparkles` icon

## [0.52.0] - 2022-10-17

### Changed

- Upgraded ruby and JS dependencies.

## [0.51.0] - 2022-10-15

### Added

- Create `ActionsDropdown::Component`

## [0.50.6] - 2022-10-14

### Added

- Add `chair`, `box-archive` and `file-export` icons
- Add option to add `custom-color` on tags

## [0.50.5] - 2022-10-14

### Added

- Add `url_field_group` form helper

## [0.50.4] - 2022-10-14

### Added

- Allow `SideMenu::Item` to render custom content

## [0.50.3] - 2022-10-13

### Added

- Add option to override when a `SideMenu::Item` should be active.

## [0.50.2] - 2022-10-12

### Added

- Add `align` option for `InfoLevel::Component`

## [0.50.1] - 2022-10-11

### Added

- `filters-alt` icon
- `closeOnClickOutside` as a value in `popup controller`. Default value is `true`.

## [0.50.0] - 2022-10-09

### Added

- Add `mode: range` for the `date_field` helper to allow for a range selection
- Create a preview for the `date_field`

## [0.49.0] - 2022-09-29

### Added

- Create `Hero::Component`

## [0.48.0] - 2022-09-29

### Added

- Create `LabelValue::Component` for displaying general values.

## [0.47.0] - 2022-09-27

### Updated

- `submit_actions` to display the cancel button in native apps when it is not being displayed inside a modal.

## [0.46.2] - 2022-09-27

### Fixed

- Display errors for `boolean_field_group` and fix styles when there are errors.

## [0.46.1] - 2022-09-27

### Fixed

- Add `is-danger` to datepicker input when there are errors.

## [0.46.0] - 2022-09-22

### Added

- `TurboNativeApp::SignOut` component.

## [0.45.1] - 2022-09-21

### Fixed

- Updated `GanttChart::Component` timeline headers calculation to fix current day flag and chart offset.

## [0.45.0] - 2022-09-15

### Updated

- Link component to add support for `native apps` when the `modal` attribute is set to `true`.
- Notification component to add `native-app` class. This class is useful for customizing the notification component when it appears in a native app.

## [0.44.0] - 2022-09-15

### Added

- Added a list footer to `GanttChart::Component`.

## [0.43.1] - 2022-09-13

### Fixed

- `dartsass-rails` requires replacing `image-url` with `url` to display icons/images.

## [0.43.0] - 2022-09-05

### Added

- Create `Progress::Component` for displaying a progress bar with percentage.

## [0.42.0] - 2022-08-30

### Added

- Create `List::Component` for displaying elements in a basic list

### Fixed

- Don't create a tippy instance when the contents are empty

## [0.41.2] - 2022-08-30

- Include third party CSS from the following libraries:
  - Trix
  - SlimSelect
  - Flatpickr

## [0.41.1] - 2022-08-29

- Allow `datepicker-controller` to enable/disabled weekends.

## [0.41.0] - 2022-08-27

- Migrate from `sassc-rails` to `dartsass-rails`
- Create new `PropertiesTable::Component`
- Add `Card::Header::Component` slot.
- Add `icon` option for `DeleteLink::Component` and add customize styles when it's inside a dropdown
- Add back button option for `PageHeader::Component`
- Update `more` icon

## [0.40.8] - 2022-08-27

- Add `month_field_group` method to generate fields with labels for date/year only inputs.

## [0.40.7] - 2022-08-24

- Added `badge-percent` icon.

## [0.40.6] - 2022-08-24

- Updated `GanttChart::Component` css to consider 4th level tasks.

## [0.40.5] - 2022-08-24

- Updated `Bali::Table::Component`. Fixes the `id` assignment for the table when `id` is defined inside `options`.

## [0.40.4] - 2022-08-24

- Updated `Bali::Table::Component`. Added an `id` to the `no records` row when the table is empty.

## [0.40.3] - 2022-08-24

- Add `infinity` icon.

## [0.40.2] - 2022-08-22

Fixes issue where using the back button resulted in the URL changing but the page not being updated. This was caused by manually manipulating the history object (history.pushState), because this interferes with how Turbo manages the restoration visits.

- removed `submitForm` function. Recommended approach is to call `form.requestSubmit()`

## [0.40.1] - 2022-08-18

Add `GanttChart::TaskActions::Component` displaying a menu with options for each task:

- Opening details
- Indent
- Outdent
- Delete

Refactor `HoverCard::Component` to use tippy to simplify and handle more options.

## [0.40.0] - 2022-08-18

Create `GanttChart::Component` for a full fledged Gantt Chart with the following functionality:

- Display a sortable and nestable list of tasks
- Fold/Unfold the nested lists
- Actions for changing the timescale between Day, Week and Month
- Button for focusing today's date and a today marker
- Draggable and Resizable tasks
- Visualize dependencies between tasks
- Display of milestones
- Resizable width of the task list
- Visualize weekends

## [0.39.1] - 2022-08-16

- Fix `Navbar` transparency.

## [0.39.0] - 2022-08-15

- Added `Clipboard` component. Copy text to clipboard.
- Added `copy`, `link-alt` icons.

## [0.38.1] - 2022-08-15

- Clean up event listeners from all StimulusJS controllers
- Override `SlimSelect#destroy` function to check for the presence of slim elements before removing them.

## [0.38.0] - 2022-08-14

- Convert `HelpTip` to a more general `Tooltip`. To create a HelpTip out of a Tooltip simply set a `<span>?</span>` as a trigger and add the class `help-tip` to the root component.

## [0.37.1] - 2022-08-12

- Update `ModalController` to check for targets (Wrapper and Background) existence before attempting action.

## [0.37.0] - 2022-08-5

- `radio-buttons-group-controller` was created.
- Update `ModalController` to look for `data-turbo` attribute in the form if it was not present in the `event.target`.

## [0.36.0] - 2022-08-4

- Update `radio-toggle-controller` to accept multiple values in current value.

## [0.35.1] - 2022-08-3

- Remove `stroke` attribute from `rect` and add `stroke` and `fill` in `svg` icons.

## [0.35.0] - 2022-08-3

- Add `under-modal` class to hide the hover-card when is necessary.

## [0.34.0] - 2022-08-3

- Add `open_on_click` property to `HoverCard::Component` to open the content on click.

## [0.33.0] - 2022-07-29

- Add `show_border` to `Reveal::Component` to show or hide the `border-bottom` just below the trigger.

## [0.32.2] - 2022-07-28

- Add `new` to CRUD actions to display an active tab when current_path is matched.

## [0.32.1] - 2022-07-28

- Remove `stimulus-chartjs` dependency.

## [0.32.0] - 2022-07-25

- Add `Timeago::Component`.

## [0.31.0] - 2022-07-25

- Add `Heatmap::Component`.

## [0.30.6] - 2022-07-18

- Add `crud` match type to `SideMenu::Item`. So it only considers items as active when current_path is one of the CRUD actions (index, show, edit.)

## [0.30.5] - 2022-07-18

- Add `starts_with` match type to `SideMenu::Item`. So it only considers items as active when current_path starts with the item's HREF

## [0.30.4] - 2022-07-18

- Only consider exact URL matches for displaying a `SideMenu::Item` as active. This fixes a problem where 2 items had a similar URL and both were considered active.

## [0.30.3] - 2022-07-14

- `step-number-input` controller was updated to be able to set a custom step.

## [0.30.2] - 2022-07-14

- Updated `PageHeader::Component` CSS to prevent overflow.

## [0.30.1] - 2022-07-12

- Updated `PageHeader::Component`, title and subtitle slots now receive an optional tag param to specify the size of the heading. New default title size is `h3` and subtitle is `h5`.

## [0.30.0] - 2022-07-11

- Create `Tags::Component` to display tags groups.
- Create `Tag::Component` to display individual tags.

## [0.29.0] - 2022-07-08

- Create `Rate::Component` to give feedback on something.

## [0.28.1] - 2022-07-08

- Allowed `InfoLevel::Component` to receive a block on its heading and title.

## [0.28.0] - 2022-07-08

- Create `Timeline::Component` to display contents in a vertical timeline

## [0.27.1] - 2022-07-07

- Update README with component updates
- Add `ImageGrid::Component` tests
- Add `Column::Component` previews
- Standardize on expect(page) syntax instead of using subject + is_expected

## [0.27.0] - 2022-07-07

- Added the `TrixAttachmentsController` for handling attachments in the `Trix` editor.

## [0.26.1] - 2022-07-07

- Fixed an issue when using icons in the content of `Reveal::Component`

## [0.26.0] - 2022-07-07

- Create `Reveal::Component` to display hidden content that can be revealed.

## [0.25.2] - 2022-07-06

- Upgrade dependencies.

## [0.25.1] - 2022-07-06

- Export `domHelpers`.

## [0.25.0] - 2022-07-05

- Add `Avatar::Component`. With this component we'll be able to see a preview of the image we want as an avatar.

## [0.24.4] - 2022-07-05

- Let `DeleteLink::Component` receive form classes for the `buttton_to` tag.

## [0.24.3] - 2022-07-05

- Add `type="button"` to Carousel controls (`arrows`, `bullets`).

## [0.24.2] - 2022-07-05

- Wrap card image slot in `slot` instead of `div`.

## [0.24.1] - 2022-07-05

- Set SideMenu list with optional title

## [0.24.0] - 2022-07-05

- `arrows` and `bullets` slots were added to `Carousel` component.

## [0.23.4] - 2022-07-05

- Fix SideMenu parent item when sub item is selected

## [0.23.3] - 2022-07-04

- Fix SideMenu sub items show only when active

## [0.23.2] - 2022-07-04

- Set `Delete` as default name for `DeleteLink::Component`

## [0.23.1] - 2022-07-04

- Add `Tabs::Trigger::Component`. In addition, a tab will cause the entire page to be reloaded when `href` is present.

## [0.23.0] - 2022-07-01

- Add `toInt` and `toFloat` JS formatters

## [0.22.0] - 2022-07-01

- Create `Carousel::Component`.

## [0.21.0] - 2022-07-01

- Create `SortableList::Component` to sort items in a list.

## [0.20.1] - 2022-07-01

- Display `SideMenu::Component` child items when item is active.

## [0.20.0] - 2022-07-01

- Create `Breadcrumb::Component` to improve the navigation experience

## [0.19.1] - 2022-07-01

- Custom notifications have been added for `no results/no records` in the table component.

## [0.19.0] - 2022-07-01

- Create `Stepper::Component` to display steps completed in a process

## [0.18.0] - 2022-06-30

- Added a `FormHelper` to add the `submit-button-controller` to the `form_for` method.

## [0.17.1] - 2022-06-30

- Update `hyphenize_keys` to return a hash in which the keys are symbols instead of strings.

## [0.17.0] - 2022-06-30

- Create `BooleanIcon::Component` and update Component Generator templates.

## [0.16.0] - 2022-06-30

- Added non-component stylesheets (`box`, `code`, `container`, `flatpickr_customizations`, `forms`, `general`, `panel`, `slim_select_customizations`, `switch`, `typography`, `variables`). In addition missing Hover Card styles (Frontend helpers) have been added to the Hover card.

## [0.15.3] - 2022-06-30

-Reorganize specs to have all tests within a bali/ folder.

## [0.15.2] - 2022-06-30

- Improve `FormBuilder` testing.

## [0.15.1] - 2022-06-29

- Pass the `options` parameter to the `SideMenu::Item::Component`.

## [0.15.0] - 2022-06-28

- Added `FormBuilder` and `FieldGroupWrapperComponent`.

## [0.14.0] - 2022-06-28

- Added `SideMenu::Component`.

## [0.13.0] - 2022-06-28

- Added Stimulus JS Controllers
  [`auto-play-audio`, `autocomplete-address`, `checkbox-toggle`, `elements-overlap`,
  `focus-on-connect`, `input-on-change`, `print`, `radio-toggle`, `submit-button`].

## [0.12.0] - 2022-06-24

- Added utils methods.

## [0.11.0] - 2022-06-23

- Added `wide` css class to `Dropdown::Component`.

## [0.10.0] - 2022-06-23

- Added conditional layout concern.

## [0.9.0] - 2022-06-22

- Added Time Value class and its corresponding tests.

## [0.8.1] - 2022-06-22

- Remove double validation in `Link::Component`.

## [0.8.0] - 2022-06-21

- Fix style in `Link::Component`.

## [0.7.0] - 2022-06-21

- Added FilterForm class and its corresponding tests.

## [0.6.0] - 2022-06-21

- Added Notification Component.

## [0.5.0] - 2022-06-17

- Completed `Loader` component.

## [0.3.0] - 2022-06-16

- Completed `Tabs` component. Added loading tab content on demand.

## [0.2.0] - 2022-06-15

- Completed `Link` and `Calendar` components.

## [0.1.0] - 2022-06-10

- `Navbar` component was added.
