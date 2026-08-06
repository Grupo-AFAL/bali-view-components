# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **A bulk action can carry an input of its own, and can open in another tab** (#724). `with_control` mounts host markup — a driver select, a date field, a `slim_select` — INSIDE that action's own `<form>`, immediately before the submit, so its value is posted alongside `selected_ids` with no JavaScript in between. This is the "assign a driver to the 12 selected shipments" shape costa-norte hand-rolled around a single form with `formaction` per button; in Bali each action is already its own form, so the control simply belongs to one of them. Declaring a control on a `method: :get` action raises `ArgumentError` at render: a GET action renders a link, a link has no form, and the value the user picked would go nowhere — the same fail-fast the filter DSL applies to an impossible `input:`. The second half is `target:`, a first-class option rather than a passthrough, because `form_with` only honours a short list of loose options (`id`, `class`, `data`, …) and swallowed a `target:` handed to it through `**options` without a word; it reaches the `<form target>` of a form action and the `<a target>` of a GET one, which is the "print the selection in a new tab and keep the selection" case. Two cautions, in the components guide and in the new **Control and target** preview: ids are per-document, so two actions mounting the same widget need distinct `id:`s (or `id: nil`) — the hidden `selected_ids` field Bali itself emits stopped carrying one for the same reason, since a bar with three actions repeated `id="selected_ids"` three times; and every action being its own form means a listing already wrapped in a form of yours gets the inner ones hoisted out by the parser, so render that form outside the listing and point a submit at it with the HTML `form="its-id"` attribute.
- **A bulk action can carry an input of its own, and can open in another tab** (#724). `with_control` mounts host markup — a driver select, a date field, a `slim_select` — INSIDE that action's own `<form>`, immediately before the submit, so its value is posted alongside `selected_ids` with no JavaScript in between. This is the "assign a driver to the 12 selected shipments" shape costa-norte hand-rolled around a single form with `formaction` per button; in Bali each action is already its own form, so the control simply belongs to one of them. Declaring a control on a `method: :get` action raises `ArgumentError` at render: a GET action renders a link, a link has no form, and the value the user picked would go nowhere — the same fail-fast the filter DSL applies to an impossible `input:`. The second half is `target:`, a first-class option rather than a passthrough, because `form_with` only honours a short list of loose options (`id`, `class`, `data`, …) and swallowed a `target:` handed to it through `**options` without a word; it reaches the `<form target>` of a form action and the `<a target>` of a GET one, which is the "print the selection in a new tab and keep the selection" case. Two cautions carried by the new **Control and target** preview: ids are per-document, so two actions mounting the same widget need distinct `id:`s (or `id: nil`) — the hidden `selected_ids` field Bali itself emits stopped carrying one for the same reason, since a bar with three actions repeated `id="selected_ids"` three times; and every action being its own form means a listing already wrapped in a form of yours gets the inner ones hoisted out by the parser, so render that form outside the listing and point a submit at it with the HTML `form="its-id"` attribute.
- **`Bali::QrScanner` — the camera half of the QR pair** (#928). `Bali::QrCode` has printed the label since #941; this reads it. `render Bali::QrScanner::Component.new` is a viewfinder that asks for the camera, decodes frames, and announces every code as `bali:qr-scanner:scan` with `{ value, result }` in the detail — `value` is the decoded string, `result` is qr-scanner's own object, which also carries `cornerPoints`. It decides nothing about what a code *means*: the host listens, fills an input, submits a form, navigates. `bali:qr-scanner:error` carries `{ state, error }` for the two ways it can fail.

  **The decoder is an optional peer, not a dependency.** `qr-scanner` (MIT, ~14 kB) is loaded with a dynamic `import()` the first time a scanner connects, so an app that never renders one never pays for it — the same contract `rqrcode` has on `Bali::QrCode`. Without it the component renders its "unavailable" state and the console names the line to run, instead of throwing an unresolved-module error into a page that otherwise works.

  **Six states, all of them in the document from the first render.** `idle`, `requesting`, `scanning`, `scanned`, `denied`, `unavailable`; the controller shows one by taking `hidden` off it and publishes the current one as `data-qr-scanner-state` on the container. A state built on demand is a state no host can restyle and no spec can find, so they are all there and the tests measure visibility rather than text.

  **Telling "blocked" from "no camera" took a second call, and it is the reason the states are worth having.** qr-scanner tries `getUserMedia` six times with different constraints, swallows every rejection (`catch(f){}`), and rethrows the single string `'Camera not found.'` — so its own error cannot distinguish a refused permission from absent hardware, and a component built on it alone can only ever say one thing. On the failure path only, the controller asks the browser once more and reads the real `DOMException`: `NotAllowedError`/`SecurityError` mean `denied` and come with a retry button, everything else means `unavailable`. The probe is deliberately *after* the failure and not in front of the camera — opening a stream only to close it and let the library open its own costs latency on every success and blinks the camera light for nothing.

  **`autostart: false` renders an idle state with a button instead of prompting on connect.** The default is `true`, which is what a dedicated scan screen wants, but a scanner inside a modal or an unopened tab must not fire a permission prompt the visitor never asked for — and a prompt that follows a deliberate press is one people say yes to. It is also what makes the Lookbook previews usable, since the alternative is a camera prompt on every reload.

  `stop_on_scan: true` (the default) releases the camera on the first code and offers "scan again" — `disconnect()` stops **and** destroys the scanner, which is the difference between a camera light that goes out and one that does not. `camera:` picks the rear (`:environment`, the default) or front lens, `highlight:` draws qr-scanner's scan-region frame, `hint:` overrides or drops the line underneath. Documented with the requirement that catches everyone out: a camera is only reachable over **https or http on localhost**, and on any other host over plain http the browser exposes none at all — which arrives indistinguishable from a device that has none, so the controller says so in the console.

  Cypress covers it without a camera by replacing `getUserMedia`: rejections for the two error states, and — for the happy path — a real `MediaStream` from a canvas with a QR code painted on it, so the decode, the event and its payload are exercised end to end. The module matrix comes from the same `rqrcode` gem `Bali::QrCode` encodes with.
- **`Bali::Chat` — the conversation surface, extracted from the two apps that had already built it twice** (#927). Three components that compose: `Bali::Chat::Component` is the scrollable region and the Turbo Stream append target, `Bali::Chat::Message::Component` is one bubble over daisyUI's `chat` grid, and `Bali::Chat::TypingIndicator::Component` is the "…is typing" placeholder. They ship no CSS at all — daisyUI's `chat`, `chat-start`/`chat-end`, `chat-bubble-*` and `loading-dots` already draw every part of this, and the bubble colour map is written out longhand so Tailwind's scanner can see the class names it has to emit.

  **The container follows a new message only when the reader was already at the bottom.** Both source implementations force-scroll on every DOM mutation, so an answer arriving while you are up in the history yanks you back down mid-sentence; `threshold:` (64px by default) says how close to the bottom still counts as following along. The decision is taken from the position recorded by the last real `scroll` event rather than measured when the message lands: an append grows `scrollHeight` while `scrollTop` stays put, so a check made afterwards reads "at the bottom" as "scrolled up by exactly the height of what just arrived" — which is why the naive version of this is always subtly wrong.

  **The typing indicator lives in the DOM permanently and hides behind a class**, which is the repo's pattern and also a fix. One of the two apps anchors its Turbo Streams to a bare `<div id="typing-indicator">` and then `broadcast_remove_to`s it, destroying the anchor: from the second message on, the `turbo_stream.replace` that should bring the indicator back silently does nothing. A node that is never removed cannot lose its anchor. Toggle it from the server by replacing it with `visible: true`/`false`, or from the page through `chat#showTyping` / `chat#hideTyping` — the indicator registers itself as a target of the container's controller, so `data: { action: 'turbo:submit-end->chat#showTyping' }` on the composer is the whole wiring.

  **The API is daisyUI's vocabulary, not either app's role enum.** The two implementations both compute a side and a colour from their own `user`/`assistant` roles and then disagree on the colour, so `position:` (`:start`/`:end`) and `color:` are what the component takes, and each host keeps its own names. It also means a support chat between two humans reads no worse than an AI one. `author:`/`timestamp:` fill the header (the timestamp as a `<time>` with a machine-readable `datetime`), and the `avatar`, `header` and `footer` slots fill the rest of daisyUI's grid — the footer is where one app hangs the source documents an answer was drawn from.

  **The bubble body is passed through untouched — no escaping, no sanitising, no `raw`.** Both apps render Markdown a language model produced, and clean it, through their own helper; which of those a host wants is a policy decision that belongs with the host, and a `raw` here would quietly take it away. Lookbook previews for the live conversation, every bubble shape, and the indicator, plus a Cypress spec that measures `scrollTop`/`scrollHeight` through all four autoscroll cases.

- **"Select all 1,248 results", not just the 20 on screen** (#724). Give `Bali::BulkActions` a `total_count:` and, once the selection covers the whole page, the bar offers to extend it to the entire filtered result. A `DataTable` declares nothing: N comes from its own `pagy` and the filters from its `filter_form`. Unchecking any row leaves the mode and returns to page selection — the Gmail move — instead of disabling the checkboxes, which would trap the user in a state only the ✕ can leave. The text is pluralized server-side into a data attribute, the same trick the bar's live region already used for `selected_one/other`, so no i18n is interpolated in JavaScript.

  **What travels is the contract, and it is deliberately explicit.** While the mode is on, `selected_ids` goes out EMPTY and two things go with the POST instead: `select_all_filtered=true`, and the `q[...]` in effect re-emitted as hidden fields inside every action's form. The server rebuilds the scope with the very code the index already runs — `MyFilterForm.new(scope, params).result` — so the params of a bulk request say exactly what was acted on and can be read in a log six months later. The alternatives were worse in the same way: a serialized query string is this with a parsing step bolted on, and "just the flag, re-derive from the persistence cache or the Referer" depends on state that may have changed between the render and the click, on a cache that is best-effort, and on persistence being on at all.

  **The params come from the RESOLVED state, not from the request URL**, which is what makes it correct under filter persistence: a listing can arrive with an empty query string and still be filtered by what the cache restored, and re-emitting the URL would claim nothing was filtered while the user is looking at 3 of 200 rows. The serialization now lives in one place, `Bali::Filters::ActiveFilterParams`, shared with the quick-search form that has always had to preserve applied filters — two implementations of "what is this listing narrowed by" would eventually disagree, and the day they did a bulk action would act on a different set than the listing showed. A GET action, which has no hidden fields, carries the same params in its href. The components guide carries the whole recipe: the offer, the exact shape of the POST, the controller that re-derives the scope, why the flag has to be cast rather than tested (it travels on every POST, and outside the mode it is the string `"false"`, which is truthy), and the two things to get right at scale — enqueue a job instead of blocking a request on 12,000 records, and put a confirmation on the destructive ones. It also draws the boundary: only the Ransack `q[...]` travel, so a listing also cut by a nav tab, a `group_by` or a controller-side scope has to pass `filter_params:` itself or the bulk will act wider than the listing showed.

  **A date range declared as an attribute travels too, and it took a fix to.** `FilterForm#result` applies `Bali::Types::DateRangeValue` attributes itself, outside Ransack, which is exactly why `active_filters` excludes them by construction — it is built from `query_params`, and that walks `non_date_range_attribute_names`. Re-emitting only what `active_filters` knows meant a listing showing 1 record handed the server enough to re-derive 2: the bulk acting on a superset of what the user could see, which at scale is a `destroy_all` reaching precisely the rows the date filter had excluded. They are now serialized separately, as the resolved `start..end` the same type casts back. The other way of declaring a date range — as a simple filter — was already covered by `active_filters` and is skipped by name, since two hidden fields sharing one `name` mean the server silently keeps one. The two paths send different things, which is worth knowing when you read a bulk request's params: the `attribute` path sends the resolved range, the simple-filter path sends the raw value, so a named period (`this_month`) travels as the token and the server re-resolves it. Since `presets:` only exist on simple date ranges, every preset travels as a token.
- **`Bali::SplitView` — the inbox shape, as a component** (#728). A master list on the left, the
  detail of the selected row on the right inside a Turbo Frame, so a row click swaps only the
  right column and the list keeps its scroll position and its highlight. `frame_id:` names the
  frame, `master_width:` sets the left column from `lg` up (default `420px`; below `lg` the panes
  stack, master on top, with no extra JavaScript), and `advance: true` puts
  `data-turbo-action="advance"` on the frame so the selection is deep-linkable. Three slots:
  `master`, `detail`, and `empty_detail` for when nothing is selected.

  **It is deliberately thin.** The component owns the responsive grid, the frame and the
  highlight controller — the three things that are identical in every master-detail screen — and
  claims nothing else. Tabs, filter chips, pagination and the rows themselves go inside `master`
  in whatever shape the screen needs, because the app this was extracted from puts all four there
  and no two screens agree on their arrangement. The grouped "InboxList" the issue also asks for
  is **not** in this release: one app has one, and one anatomy is not enough to triangulate an API.

  **The selection is an attribute, not a class list.** The `split-view` Stimulus controller moves
  `aria-current` between rows and the look follows from `.split-view-row[aria-current]` in the
  package stylesheet, so the selected state cannot fall out of a Tailwind build the way class
  names toggled from JavaScript can. It is drawn with an inset `box-shadow` rather than a left
  border, measured: rows are separated with `border-b border-base-200/70`, and that colour utility
  claims all four sides from Tailwind's utilities layer, which beats `@layer components` outright
  — a `border-l-primary` in the component sheet rendered base-200 and the highlight was invisible.
  The shadow also paints inside the padding box, so the selection moves between rows without
  shifting a pixel of text. `data-split-view-selected-class` is there for a host that wants more.

  **Back and forward behave.** A row click promotes the frame swap to a Turbo visit, and the
  snapshot Turbo caches for the page being left is taken between the click and the frame's
  response — so it holds the highlight the controller had just moved next to the detail pane from
  *before* the swap, and pressing back restored a master pointing at one row with an empty detail
  beside it. On a history traversal the controller now re-derives the highlight from the URL
  instead of trusting that snapshot, which it can do because each row's href *is* the URL that
  selects it. Only on a traversal: on a first paint the server's markup wins, since a master can
  live on a page whose URL is not in its rows' URL space at all. The href and the location are
  matched on path plus query params **as a set**, not as one string — the two are built by
  different code paths, so the location routinely carries params the href never had (a page
  number, a sort) and lists the shared ones in another order, and a string comparison called
  those a different place and dropped the highlight.

  `.split-view-scroll` is an opt-in class for whichever part of the master should scroll — usually
  the list alone, so tabs above it and pagination below it stay put — reading
  `--bali-split-master-max-h` (default `calc(100vh - 20rem)`) so each screen can tune it to its own
  chrome. `--bali-split-master-width` carries `master_width:` for the same reason a Tailwind
  arbitrary value cannot: the width is a runtime value the build never sees.

  The component is half the screen and the other half is the host's, so
  **`docs/guides/master-detail.md`** carries the rest of the pattern: the whole Rails side in
  one action, why the row's href has to hold the current filters, the two different empty
  states a filtered list needs (composed from `Bali::EmptyState`'s `cta` slot, not added as an
  option — "no results" beside filters the reader set is a dead end, and the useful thing is a
  way out of them), and the full-page-detail-on-a-phone variant. That last one hinges on a
  measured Turbo fallback: a frame in the DOM is swapped **even under `display: none`**, and
  only a frame that is absent turns the row click into a full visit — so whether a phone gets
  the split view at all is a server-side decision, and `lg:hidden` will not make it. The guide
  also covers what happens when the detail request **fails**, which splits two ways and is the
  one corner that looks fine on screen: a response carrying
  `<meta name="turbo-visit-control" content="reload">` (Rails' own exception page does) becomes
  a full-page visit, while any other response without a matching frame is *ignored* — the pane
  keeps its previous detail while the optimistic highlight has already moved, and the two
  disagree silently until the next click.

## [v3.1.0.beta.5] - 2026-08-06

### Added

- **`Bali::SideMenu` takes a `theme:`** (#726). The keyword emits `data-theme` on the `<nav>`, which is the whole of "the sidebar is dark and the page is not": daisyUI resolves its colour variables against the nearest ancestor carrying one. The theme's values stay in the host — chrome colours are brand — and `docs/guides/custom-themes.md` now carries the ~18-token recipe measured in costa-norte, the app that ran this pattern in production first. A themed sidebar also fixes its flyout panels on its own: on a dark surface daisyUI's soft shadow is invisible and a `base-100` panel is the same colour as the rail it opens from, so the panels render one step lighter with a real border and a shadow that reads against dark. The `dark_chrome` Lookbook preview shows the whole arrangement next to light content.

- **`Bali::AppLayout` takes `mobile_bottom_padding:` for the bottom of a phone screen** (#726). Off by default; when on, it puts room under the content so the last row of a list or the submit button of a long form is not stuck behind the phone's own chrome. It covers two problems that are easy to confuse: the home indicator, which is real and comes from `env(safe-area-inset-bottom)` (and is `0px` everywhere else, so it costs nothing on a desktop), and Safari's floating bottom bar, which hovers **over** the page and is **not** reported by `env()` at all — hence a flat `4rem` under `sm` next to the environment value rather than instead of it. Documented with the setup the insets need to report anything in the first place (`viewport-fit=cover`, plus `theme-color` while you are in there), which is the host's `<head>` and not Bali's to render. The padding lands on `<main>`: the body container's own padding is a Tailwind utility, and a utility beats `@layer components`, so a rule on the container would never have applied.

- **`Bali::AppLayout` offsets the pinned sidebar under the banner, by measurement** (#726). A banner — impersonation, maintenance, "you are in beta" — is a full-width strip, and the fixed sidebar now starts below it instead of painting over it. Nothing has to be declared: the new `app-layout` Stimulus controller keeps a `ResizeObserver` on the strip and publishes its height as `--bali-banner-height` on `<body>`, which the sidebar's `top` and `height` read. That covers the cases a constant cannot — two banners stacked (gc hardcodes `top: 5.5rem !important` for exactly that pair), a banner the user dismisses, one a Turbo Stream adds later, one that wraps to two lines on a phone — and it removes the `--banner-height` TODO the apps have been carrying. The strip is `position: sticky` so an impersonation warning survives scrolling; under `viewport_locked: true` the body does not scroll and sticky is inert. Only the height is JavaScript: the offset is one CSS rule reading `var(--bali-banner-height, 0px)`, so a page whose JS has not run, or a host that never registers the controller, renders exactly as before. New `with_banner` Lookbook preview (two stacked banners, the second dismissible) and a Cypress spec that measures the rail's computed `top`/`height` against the strip.
- **`Bali::WorkflowSteps` gets the horizontal "quick flow" and the decision-form pattern** (#716). `variant: :horizontal` renders the same steps as a row of cards with an N/M progress bar on top — the shape for a summary card or a table cell, where the whole chain has to fit in a glance. Same `with_step` API; the marker becomes a dot and there are no connectors, because the bar already says how far the flow got. **N counts the steps with a verdict** (`:success`, `:error`, `:warning`, `:skipped`): a skipped step is settled and it is still one of the dots on screen, so counting it keeps N/M matching what the reader can count; `:pending` and `:current` are the two that have not happened yet. **The bar takes the flow's verdict** — red if any step was rejected, amber if any came back with observations, neutral otherwise — so a broken chain reads as broken without reading it. `progress: false` drops the bar; asking for one on the vertical variant raises, since that shape has no header to hang it on. The cards wrap on their own (`auto-fit` from 11rem) instead of shrinking past reading width, and `:skipped` draws a **hollow** dot rather than the vertical variant's dash: with no number left to read, two greys at that size were the same dot.
- **The approve/reject decision form is documented, not packaged** (#716). One form, two submits told apart by `name: "decision"` / `value:`, `required: true` on the notes and `formnovalidate` on Approve — which is what makes the browser demand a reason to reject and ask nothing to approve, with no JavaScript and no second field — plus `turbo_confirm` on the destructive half only. It is a `Bali::FormBuilder` recipe end to end (`text_area_group` + two `submit_field`s), in the components guide and in the new `decision_pattern` Lookbook preview. Deliberately not a component: the form owns the host's route, params and policy, and packaging `formnovalidate` would be the first step towards the workflow engine this component is not.
- **`auto_submit: true` per filter: SimpleFilters pills that filter on click** (#725). A `:toggle_group` or `:radio_group` declared with `auto_submit: true` submits the row the moment it changes, so a segmented control behaves like the tab strip it looks like instead of asking for a second click on Filter. `filter_attribute :status, type: :select, simple: true, input: :radio_group, auto_submit: true` — and the instance-level `simple_filters:` hashes take the same key. It is **opt-in per filter and off by default**, so no existing row changes: `submit-on-change` is mounted on the form only when some filter asked for it, only that filter's controls carry the action, and the Filter button stays for the filters that did not opt in. Only the two pill widgets accept it and anything else raises at class-definition time, because one click is the whole interaction on a pill while a date or number range would submit between the two halves of its value. No new controller and no new JavaScript: this is the extended `submit-on-change` from #717, whose connect guard is what keeps the row from submitting itself while it is still being built.
- **`size:` is a density on every FormBuilder family, not just the text inputs** (#723). The
  foundation shipped the discrimination — a Symbol is daisyUI's variant, an Integer or String
  stays the HTML attribute of the same name, an unknown Symbol raises — and this completes the
  rollout, so a form written entirely at one density comes out at that density:
  `select_group`/`time_zone_select_group` → `select-*`, `text_area_group` → `textarea-*`,
  `range_group` → `range-*`, `file_group` → `btn-*` on its CTA, and `checkbox-*`/`toggle-*`/
  `radio-*` gain the `:xl` daisyUI 5 added. `slim_select_group` keeps `:sm`, the one density its
  widget has CSS for, and now raises on the others instead of silently rendering full-size.
  Captions, help text and error messages need no variant of their own — daisyUI scales them with
  the fieldset. New preview **Form / Sizes** (compact form, and the same fields side by side with
  and without the option). Every family declares its outcome in
  `test/bali/form_builder/size_option_test.rb`, which fails if a new one lands in neither list.
- **`f.date_group :on, alt_input: true, size: :sm`** now sizes the input the user actually sees.
  With `alt_input:` flatpickr hides the real input and draws a second one from
  `alt_input_class`, which the density never reached.
- **Date range filters take named periods — "This month" instead of two dates** (#725). `filter_attribute :created_at, type: :date, input: :date_range, simple: true, presets: %i[today this_week this_month]` (or `presets: true` for all five: `today`, `this_week`, `this_month`, `last_7_days`, `last_30_days`, the trailing two inclusive of today) renders a period select whose "Custom…" option reveals the picker that was there before. An instance-level `simple_filters:` hash takes the same key. An unknown token raises at declaration time, and so does `presets:` on anything but `date_range` — "this week" is not a value a single date can hold, and a control that cannot work should not render.

  **The token is what travels, and that is the point.** `q[created_at]=this_month` goes in the SAME param an explicit range does, and `Bali::Types::DateRangeValue` only resolves it to a real range when the query runs. So a saved view or a persisted filter built on one still means this month next month, where a stored `2026-08-01..2026-08-31` means August forever — which is exactly the complaint that produced the issue. The period is the server's `Time.zone`, the zone the rest of the date filtering already speaks; resolving it in the browser would use the visitor's and quietly disagree with the listing it filters.

  **The cast is additive, measured token by token.** Three of the five (`today`, `this_week`, `last_7_days`) used to reach `Time.zone.parse`, come back `nil` and raise `NoMethodError`. The other two did produce a range and both were nonsense: `Date._parse` reads the "mon" inside `this_month` as a weekday and yields today, and pulls `mday: 30` out of `last_30_days` and yields the 30th of the current month. Those two literal strings are the only inputs whose result changes, from a silently wrong day to the period they name. Every other form the type accepts — `a..b`, the beginless and endless halves, the localized `2026-01-01 to 2026-03-31`, a bare date widening to its whole day — is covered by the new `test/bali/types/date_range_value_test.rb` and unchanged.

  **No second Stimulus controller.** The widget is `time-period-field`, the one `f.time_period_group` has always built, given a `custom-value` so the option that reveals the picker can be named. It defaults to the empty string — what the form builder uses, since its blank option is spent on "custom" — while a filter row needs its blank for "any date" and passes `custom`. Two fixes came with it: the container named by `date-input-container-class` is now resolved before the first toggle rather than after, so it is hidden on the initial render instead of one interaction later; and the hidden field is the only control in the widget with a `name`, since two inputs sharing one submit the param twice and the server keeps the last, not the one on screen.
- **`dynamic_fields_group` grows a table mode and an array mode** (#715). The same helper, the
  same anatomy — header, container, `<template>` — with two shapes it could not produce before,
  both opt-in and both leaving existing call sites byte-for-byte unchanged:
  - `table: true` renders the container as the `<tbody>` of a table the helper emits, so the row
    partial writes `<tr>`. `columns:` fills the `<thead>` and `table_class:` overrides the default
    `table`. The header and its `<template>` render *outside* the `<table>`, which is the only
    place they survive: the HTML parser hoists a `<div>` sitting between `<table>` and `<tbody>`
    out of the table, which used to strand the add button and its template. A `<tr>` inside the
    `<template>` is fine — the HTML5 parser switches to "in table body" for exactly that case.
  - `array: true` names the rows `movie[steps][][role]` for an attribute that is a plain array of
    hashes rather than an association: no `fields_for`, no `_destroy`, no
    `reflect_on_association` to explode on. Rows come from the attribute or from `values:`, and
    the partial receives `name_prefix:`, `item:` and `index:` alongside `f`. Checkboxes are not
    supported in this mode — Rails' paired hidden field repeats a key inside the element and
    splits the array — see the guide.
  - `partial:` on both `dynamic_fields_group` and `link_to_add_fields` names the row partial
    explicitly instead of deriving `_<singular>_fields`, and `destroy_flag: false` on
    `link_to_remove_fields` drops the hidden `_destroy` for rows that have nothing to destroy.
- **`dynamic-fields` renumbers a visible ordinal** (#715). A `data-dynamic-fields-target="ordinal"`
  element inside a row gets the row's 1-based number written into it after every add, remove and
  reorder, counting only the rows still in play. The target holds the number alone, so punctuation
  around it ("1.", "#1") lives in the markup and survives renumbering. Absent target, nothing
  happens — this is the piece host apps were each writing a controller for.


- **`submit-on-change#debouncedSubmit`, so one form can mix immediate and debounced controls** (#717). The controller has always had a `delay` value, but it applied to the whole form: either every control waited or none did, which is why a filter row with a select and a search box needed two controllers (or, in three AFAL apps, a local `auto_submit_controller.js` copy that had grown the pair on its own). `submit` stays as it was and `debouncedSubmit` is always debounced, so `<select data-action="submit-on-change#submit">` next to `<input type="search" data-action="submit-on-change#debouncedSubmit">` is now the whole wiring. `delay` still governs both actions when set; without it `debouncedSubmit` waits 300 ms. New `bali/submit_on_change/default` preview and `cypress/e2e/submit-on-change.cy.js` cover both actions, and `docs/guides/controllers.md` has the markup.

- **`char_counter:` works on a text field, not just a textarea** (#723). `f.text_group :headline, char_counter: { max: 80 }` renders the same live count under the control that `text_area_group` has had, because it is the same thing: the Stimulus controller behind it only reads `value.length`, so an `<input>` and a `<textarea>` are indistinguishable to it. `{ max: n }` counts against a maximum and turns the counter red past it; `true` just counts. The typing is never stopped — the count is an advisory, so pair it with `maxlength:` and a model validation when the limit has to hold. New preview **Form / Text → With Character Counter**, a `char-counter.cy.js` spec that runs the same expectations against both controls, and the option finally documented in the FormBuilder guide.



### Changed

- **`BlockEditorController` now inherits from `ReactIslandController`** (#703). No API change
  and nothing to do in a host app: the controller identifier, its Stimulus values, the entry
  and `block_editor_meta_tags` are all untouched. What changed is where the mechanics live —
  the `_disconnected` guard, `createRoot` over its own mount point, the `turbo-cache-control`
  meta, the unmount on disconnect and the error fallback now come from the base the editor
  was extracted from, and the controller keeps only what makes it the block editor: the
  BlockNote wrapper, the props, the submit flush, the ProseMirror teardown (moved to the
  base's `beforeUnmount` hook, which runs while the DOM is still attached) and the PDF/DOCX
  exports. The editor is the first real subclass, so this is what proves the base's hooks fit
  a demanding island rather than only the toy preview. It also gains the base's
  ErrorBoundary, which it never had: a render error inside the editor now shows the fallback
  message instead of tearing down the React tree.

- **Removing an unsaved row deletes it from the DOM** (#715). `dynamic-fields#removeFields` used to
  hide every removed row and flag it `_destroy`, whether or not there was anything to destroy. It
  now looks for the `[id]` hidden field `fields_for` emits only for a persisted record: with one,
  the old behaviour (hide, strip the visible inputs, flag) so the server still learns which record
  to delete; without one, the row simply leaves the DOM. What gets submitted is unchanged —
  `_destroy` on a nested hash with no `id` was already a no-op — but the DOM stops accumulating
  dead rows. `resetPositionValues` skips hidden rows for the same reason, so `[data-position]`
  stays contiguous over the rows that will actually be saved, and it now tolerates a row without a
  position input instead of raising.
- **`submit-on-change` ignores change events fired in the frame it connects in** (#717). SlimSelect dispatches a `change` on the native `<select>` while it builds its widget over it — measurable whenever the options carry `data-inner-html`, which makes it rewrite the element — and a form carrying `submit-on-change` submitted on that event, before the user had touched anything. Measured against the new preview with the guard off: the page navigates to `?form_record[select]=1&form_record[text]=` on its own. This is a behavior change, not only a fix: any change event in the first frame after `connect()` is now dropped, including one your own code dispatches there. `data-submit-on-change-skip-initial-value="false"` restores the old behavior. Two incidental fixes ride along: a pending debounced submit is cancelled on `disconnect()` instead of firing at a detached form, and reconnecting the controller no longer wraps the debounce around itself (a form that connected twice used to wait `delay` twice).
- **`Bali::AppLayout` offsets the pinned sidebar under the banner, by measurement** (#726). A banner — impersonation, maintenance, "you are in beta" — is a full-width strip, and the fixed sidebar now starts below it instead of painting over it. Nothing has to be declared: the new `app-layout` Stimulus controller keeps a `ResizeObserver` on the strip and publishes its height as `--bali-banner-height` on `<body>`, which the sidebar's `top` and `height` read. That covers the cases a constant cannot — two banners stacked (gc hardcodes `top: 5.5rem !important` for exactly that pair), a banner the user dismisses, one a Turbo Stream adds later, one that wraps to two lines on a phone — and it removes the `--banner-height` TODO the apps have been carrying. The strip is `position: sticky` so an impersonation warning survives scrolling; under `viewport_locked: true` the body does not scroll and sticky is inert. Only the height is JavaScript: the offset is one CSS rule reading `var(--bali-banner-height, 0px)`, so a page whose JS has not run, or a host that never registers the controller, renders exactly as before. New `with_banner` Lookbook preview (two stacked banners, the second dismissible) and a Cypress spec that measures the rail's computed `top`/`height` against the strip.
- **One wrapper builds the counter for every family that can have one** (#723). `text_area_field` used to build its own `.control` div next to a second copy of the error and help paragraphs — the arrangement that once made a textarea with a counter render neither. The controller, its values and the counter element now come from `field_helper`, the one place that decides how a control is wrapped, so the two spellings cannot drift apart again. No markup change: the textarea's existing tests pass untouched. `TextAreaFields::COUNTER_CLASS` is now an alias of `HtmlUtils::COUNTER_CLASS`.

- **The `Bali::AppLayout` banner no longer clears the fixed sidebar horizontally** (#726). A beta gave `.app-layout-banner` the same `padding-left: var(--bali-side-menu-width)` as the navbar and the content, because the sidebar was pinned at `top: 0` and painted over the strip's left edge. The sidebar now starts *below* the banner instead, so there is nothing left to clear: keeping the padding would indent a full-width strip into the content column and leave a band of empty page above the sidebar. The navbar and the content keep their offset — that half of the fix is untouched. A host that styled around the indented banner (a background that started at 16rem, a left-aligned logo inside the strip) will see the strip move left to the viewport edge.



### Fixed

- **The Gantt island's drag spec no longer degrades the dummy database it runs against** (#705).
  `gantt-island.cy.js` dragged a bar forward and then dragged it back "the same distance" to
  restore the seeded dates. The return drag is not the inverse of the outbound one — measured on
  the seeded fixture, the outbound drag moves the item 5 days and the return drag moves it 0 — so
  every local run left the item ~5 days later than it found it. Once the item drifted past the
  start of the next one, the return drag landed on the date the item already had,
  `onNodeDragStop` short-circuited before posting, and `cy.wait('@patch')` timed out waiting for a
  second request that never came. CI never saw it because every CI run does
  `db:schema:load db:seed` first; locally it surfaced after a handful of repetitions and looked
  like a race in the island. The spec now waits for the reconcile to land in the table before
  asserting, and restores the item through the contract's own PATCH endpoint instead of through a
  second drag — deterministic, and it leaves the database exactly as it found it. Verified with 8
  consecutive runs: 8/8 green with the seeded dates unchanged (before: 0/8 from a drifted
  database).

- **`size:` no longer leaks into the markup as an attribute where it means nothing** (#723).
  `slim_select_group(size: :sm)` emitted `<select size="sm">` next to the wrapper class — Rails'
  `select_content_tag` copies `:size` out of a select's options and onto the element, so closing
  one route was not enough. The families whose control is a widget over a hidden field
  (`rich_text_group`, `block_editor_group`, `coordinates_polygon_group`, `time_period_group`)
  painted `<div size="sm">` for the same reason `<div required>` used to appear there; `size`
  joins `required` in `CONTROL_ONLY_OPTIONS`.



## [v3.1.0.beta.4] - 2026-08-06

### Added

- **Acknowledgments and read coverage: `Bali::Acknowledgeable` + `Bali::ReadCoverage`** (#709). "I read and confirm this" is the same ledger in every app that has ever needed it, so the engine now ships it:
  - New table `bali_acknowledgments`. **Both** halves are polymorphic — the signer (`user`) and the thing signed (`acknowledgeable`) — so one table serves documents signed by `User`s and agreements signed by `Member`s without Bali knowing either class. Unique on `[acknowledgeable_type, acknowledgeable_id, user_type, user_id]`: one signature per person per record, always.
  - `include Bali::Acknowledgeable` gives a model `acknowledge(user:)`, `acknowledged_by?(user)` and `acknowledgments`. No macro to configure: the only thing the concern asks the model is `version_label`, and it asks with `try`, so a model without versions works unchanged.
  - `acknowledge` is **idempotent for the same version** — confirming twice returns the existing signature untouched, which is what makes `acknowledged_at` usable as evidence. When `version_label` has changed the person is signing a different text, so the label **and** the date move together on the same row, rather than leaving a record that claims someone signed v2.0 before v2.0 existed.
  - `content_version_id` is nullable and carries **no foreign key**, so installing the signature book never forces installing the content-versions table; it fills itself in when both are present, and a caller can always name it.
  - `Bali::ReadCoverage.new(record, audience:, threshold: 80)` answers how much of an audience has signed: `total_count`, `confirmed_count`, `pending_count`, `confirmed_users`, `pending_users`, `coverage_percentage`, `below_threshold?`. The audience is **injected**, because where it comes from — a department, a role, an explicit reader list — is the part every app does differently. One query for the signatures regardless of audience size, and no grouping by area: that is the host's domain.
  - **An empty audience has no coverage, not zero coverage**: `coverage_percentage` returns `nil` and `below_threshold?` returns `false`. `0/0` is not `0`; reporting 0% would paint a dashboard red over records nobody has to read, and 100% would claim a coverage nobody confirmed.
  - No acknowledgments controller in the engine, on purpose — the valuable part of one is a `turbo_stream` that renders a partial *of the host*. The twenty-line recipe, whitelist included, is in the new guide.
  - New guide `docs/guides/engine-models.md`: the adoption path for every table the engine ships (saved views and acknowledgments today, the rest of the documents engine as it lands), plus what to change when porting the schema from gobierno-corporativo.
- **Entity references move into the engine, behind one registry per type (#708).** The
  BlockEditor's `#` menu had a working front end and no server: every host wrote its own
  search endpoint, its own resolver and its own display config, three parallel declarations
  that drifted. Now `Bali.entity_reference_types` declares a type once — `search_scope`,
  `lookup_scope`, `search_fields`, `display_field`, and optionally `url`, `unreachable?`,
  `extra_payload`, `permission_scope` and `display` — and that single entry powers the
  search endpoint, the resolution endpoint **and** the editor's `references_config`, which
  the component now derives when the host doesn't pass one.
  - `Bali::EntityReferencesController` serves both operations for every registered type at
    once (`GET bali/entity_references?q=`, `POST bali/entity_references/resolve`), capped at
    10 results and 5 per type, with the query escaped through `sanitize_sql_like`.
    `Bali.entity_references_authorize` **denies by default**: mounting the engine publishes
    no search over your records until you open it, and `permission_scope:` gates each type
    on both search and resolution, so a record the viewer may not see resolves as broken
    rather than disclosing its name.
  - `Bali::EntityReferenceable` materializes the references embedded in a model's BlockNote
    column into the new `bali_entity_references` table (`record` and `referenceable` both
    polymorphic, no foreign key on the referenced side so a reference survives the deletion
    of its target and still renders as a broken chip). The write is a minimal diff guarded
    by `saved_change_to_<attribute>?`: an autosave that doesn't touch the content costs no
    queries, and rows that are still there keep their ids. `references_entities_in :body`
    names the column when it isn't `content`; `incoming_references` and
    `Model.referencing(record)` walk the relation backwards.
  - `Bali::BlockNote::Text.entity_references` is the single walker over BlockNote structure
    (nested children, both table shapes), shared with the text extractor — the reason the
    hand-rolled versions this replaces drifted apart was having two.
  - The payload the browser receives — `entityType`, `entityId`, `entityName`, `url`,
    `broken` — is frozen; `extra_payload` adds host-owned keys on top of it and cannot
    override those five. Adoption guide: `docs/guides/engines.md`.
  - Caps on both sides, because the `after_save` runs inside the host's own `update!` and
    the request body is written by the client: 500 references per record, 500 refs per
    resolve request, 255 characters of `reference_text`, ids that don't fit a bigint
    dropped, and no search below two characters.

- **Polymorphic content versions: `Bali::ContentVersionable` + `Bali::ContentVersionsController`** (#707). The `DocumentEditor`'s history panel has been a JSON contract with no server behind it — every host reimplemented the same `create_version!` / `create_or_coalesce_version!` pair, the same numbering, the same restore, and the dummy's copy did it without the row lock (which is the bug, not the pattern). The engine now ships all of it:
  - New table `bali_content_versions`: a polymorphic `record`, so a document, a policy and a note share one history table without Bali knowing any of those models. `version_number` is unique per record, `content` is jsonb on Postgres and json everywhere else, and `has_one_attached :file` is there (no presence validation) for the "version of a file" case.
  - `include Bali::ContentVersionable` gives a model `content_versions`, `create_version!`, `create_or_coalesce_version!`, `content_at_version` and `restore_content_version!`. `content_versionable attribute: :content, coalesce_window: 5.minutes` configures it — the window is a property of the model, not of the app, because how long one editing session lasts depends on what is being edited. A burst of auto-saves by one author inside the window updates the last version instead of creating twelve, under a row lock so two concurrent saves cannot claim the same `version_number`.
  - The author is a polymorphic **optional** association plus a required denormalized `author_name`: the JSON the editor consumes serves the name, so a host with no user model loses nothing, while the foreign key makes "my versions" and auditing possible without a later migration. Coalescing compares by `(author_type, author_id)` when there is an author record, so two people with the same name never collapse into one version.
  - `Bali::ContentVersionsController` serves index, show and restore. The record travels in the query string (`?record_type=&record_id=`) because the engine cannot nest routes under models it does not know, and each version carries its own `url` — the shape the JavaScript already prefers over interpolating one.
  - Two default-deny gates: `Bali.content_versionables` is a whitelist of `record_type` → resolver, empty by default, so every type is a 404 until a host names one (without it, `record_type` would be a `constantize` over user input); `Bali.content_versions_authorize` receives the action, so reading and restoring can be gated apart, and returns falsy by default → 403. `Bali.content_versions_author` names who signs the version a restore creates.
  - `Bali::DocumentEditor::Component` accepts `versions_url: :auto` / `restore_version_url: :auto` plus `record:`, resolving to the mounted engine's endpoints. Without a record the history panel does not render, rather than rendering one whose every request would 404. Plain string URLs keep working untouched.
  - Adoption guide in `docs/guides/engines.md`, including the explicit note that a host with an existing history table **does not have to migrate** — the contract is JSON.
  - The dummy app now consumes the engine instead of its own `DocumentVersion`, which is what proves the adoption path works.
  - Both `create_version!` and `create_or_coalesce_version!` take a row lock, so they must be called **after** the record is saved: Rails refuses to lock a record with unsaved attributes, which means versioning mid-edit raises instead of recording a snapshot the database never held. `summary` is capped at 255 characters in the column and in the model, and `restore_content_version!` re-scopes the version to the record it is called on even when handed a `Bali::ContentVersion` object, so one record can never be restored from another's history.
- **The engine now stores the Block Editor's inline comments** (#706). Three tables
  (`bali_block_editor_threads` / `_comments` / `_reactions`, installed with
  `bin/rails bali:install:migrations`), three controllers, and the nine endpoints
  `RESTThreadStore` has always called — so a host stops re-implementing the reference
  controllers by hand. Point the editor at them with `comments: { url: :auto, commentable: record }`:
  it resolves `bali.block_editor_threads_path(commentable_type:, commentable_id:)` for that
  record, and `_buildUrl` carries the scope to all nine sub-requests for free. Passing `:auto`
  without a `commentable:` raises — there is no unscoped thread list, deliberately.
  - Three lambdas are the whole configuration, and all three deny by default:
    `Bali.block_editor_commentables` (default `{}`, so mounting the engine grants nothing;
    a type nobody listed and a record that does not exist are both `404`, and
    `commentable_type` is never `constantize`d), `Bali.block_editor_comments_user`
    (returns the string author id) and `Bali.block_editor_comments_authorize`
    (`403` when it says no).
  - Permissions replay BlockNote's own `DefaultThreadStoreAuth` server-side, because the
    client-side copy stops nothing: anyone admitted may list, open a thread, comment, resolve
    and react; only a comment's author may edit or delete it; only the author of a thread's
    **first** comment may delete the thread. Deleting a comment is soft (null body plus
    `deleted_at`), and deleting the last live comment takes the thread with it.
  - `commentable_type`/`commentable_id` are **required on every action**, including the ones
    that already carry a thread id. That is what keeps `GET /` from being "every thread in the
    database" — the leak the reference implementation shipped with.
  - The `X-User-Id` header the store sends is ignored on purpose; identity comes only from
    `Bali.block_editor_comments_user`. There is no user-directory endpoint either: display
    names stay the host's business through `comments[:users]` / `users_url`.
  - `as_json` is a frozen wire contract (`test/bali/block_editor_json_contract_test.rb` fails
    the build on a renamed key), and the dummy app now consumes the engine instead of its own
    copy — that substitution is the adoption test. Adoption, the permission matrix and the
    three-`rename_table` migration for apps that already ran the reference implementation are
    documented in `docs/guides/engines.md`.
- **`Bali::WorkflowSteps` gets the horizontal "quick flow" and the decision-form pattern** (#716). `variant: :horizontal` renders the same steps as a row of cards with an N/M progress bar on top — the shape for a summary card or a table cell, where the whole chain has to fit in a glance. Same `with_step` API; the marker becomes a dot and there are no connectors, because the bar already says how far the flow got. **N counts the steps with a verdict** (`:success`, `:error`, `:warning`, `:skipped`): a skipped step is settled and it is still one of the dots on screen, so counting it keeps N/M matching what the reader can count; `:pending` and `:current` are the two that have not happened yet. **The bar takes the flow's verdict** — red if any step was rejected, amber if any came back with observations, neutral otherwise — so a broken chain reads as broken without reading it. `progress: false` drops the bar; asking for one on the vertical variant raises, since that shape has no header to hang it on. The cards wrap on their own (`auto-fit` from 11rem) instead of shrinking past reading width, and `:skipped` draws a **hollow** dot rather than the vertical variant's dash: with no number left to read, two greys at that size were the same dot.
- **The approve/reject decision form is documented, not packaged** (#716). One form, two submits told apart by `name: "decision"` / `value:`, `required: true` on the notes and `formnovalidate` on Approve — which is what makes the browser demand a reason to reject and ask nothing to approve, with no JavaScript and no second field — plus `turbo_confirm` on the destructive half only. It is a `Bali::FormBuilder` recipe end to end (`text_area_group` + two `submit_field`s), in the components guide and in the new `decision_pattern` Lookbook preview. Deliberately not a component: the form owns the host's route, params and policy, and packaging `formnovalidate` would be the first step towards the workflow engine this component is not.


### Fixed

- **An entity reference chip no longer links to a `javascript:` URL.** The chip's `url` prop
  lives inside the saved document, so it is written by whoever can edit the content, and it
  reaches the `href` untouched whenever resolution doesn't run (no `references_resolve_url`,
  or a failed request). React renders `javascript:` hrefs with nothing but a console
  warning. The chip now renders as plain text unless the URL is `http(s):`, `mailto:`,
  root-relative or a fragment.
- **`Bali::WorkflowSteps` names each step's state for a screen reader** (#716). Both markers said the state in colour and nothing else — the circle's number is a position, not a verdict, and the quick flow's dot has no text at all — so "3, Legal review" was everything a screen reader got about a rejected step. Every step now renders an `sr-only` span with the state's name next to its marker, **in both variants**, from six new keys under `bali_view.workflow_steps.states.*` (en/es) that a host overrides like any other Bali string when its domain has better words ("Signed", "Returned", "Waiting on legal"). The span sits *outside* the circle, so the number stays the circle's whole content.
- **A field with `char_counter:` no longer writes its Stimulus wiring into the caller's options hash** (#723). The two helpers that add `data-` attributes mutate in place, and the `:data` key they reach is the caller's own object — so reusing one options hash across two fields would have carried the first field's target and action into the second. Caught by `options_contract_test.rb`, which exists for exactly this.
- **The textarea controller stays quiet when it has no control to act on** (#723). `auto_grow:` belongs to the textarea — an `<input>` has no height to grow into — so a text field written with it now gets a controller and no input target. Before the guard that would have thrown "Missing target element" on connect, where it used to do nothing at all; doing nothing is the right answer, and it is now the measured one.


## [v3.1.0.beta.3] - 2026-08-06

### Changed

- **The Gantt island follows the viewport without re-rendering** (#705). Panning, dragging a bar,
  selecting and typing in the search box each used to re-reconcile the island's entire React tree;
  on a 300-item document (20 groups, 150 dependencies) a single pan frame rebuilt every row of the
  left table, every tick of the axis and every bar of the minimap. No public API, markup, CSS or
  data-contract change — only how the components subscribe to the canvas:
  - The layers that shift as a block with the pan (time header, grid + weekend bands, row bands,
    group summary bars, today line, left table, minimap viewport rectangle) no longer subscribe to
    the React Flow transform with `useStore`. They take it from the store imperatively (new
    `useViewportFollow` hook) and write `style.transform` on a ref, so a pan frame costs **zero**
    React renders instead of one per layer plus all of its children. Measured over 20 pan frames:
    horizontal 100 component renders → 0; vertical 20 renders + 6.400 table rows → 0.
  - `React.memo` on the chrome (`GanttTable` and its `Row`, `Toolbar`, `TimeHeader`, `GridBands`,
    `RowBands`, `SummaryBars`, `Minimap`, `GanttFooter`), with the toolbar's toggle callbacks
    given stable identities so the memo actually holds. Dragging a bar re-rendered the whole
    chrome once per pointer frame (3.200 row renders over 20 frames); it now re-renders only the
    dragged bar. Same for the table splitter: 6.080 row renders → 0.
  - Node decoration runs in two passes, so the `selected` bit no longer rebuilds every bar's `data`
    object: React Flow keeps its internal node for the bars whose bit did not change and only the
    affected ones re-render. A selection click went from 300 bar renders + 640 row renders to 1
    and 1.
  - `useDeferredValue` on search and status filter: the input echoes the keystroke immediately
    while the model rebuild is deferred, so a burst of keystrokes rebuilds the filtered document
    once instead of once per letter (9 letters: 5.760 row renders + 2.700 bar renders → 320 + 300).
### Added

- **`Bali::QrCode` — QR codes generated server-side, with `rqrcode` as an optional dependency** (#926). `render Bali::QrCode::Component.new(payload: movie_url(@movie))` emits inline SVG: no JavaScript, no image request, nothing to serve. `payload:` is required; `size:` (pixels, default 200) and `level:` (error correction `:l`/`:m`/`:q`/`:h`, default `:m`) are the whole API. The gem it encodes with is **not** in the gemspec — three apps in the org render QR codes and the rest would carry it for nothing — so it is required lazily and its absence raises `Bali::QrCode::Component::MissingDependency`, a `LoadError` subclass whose message names the line to add (`gem "rqrcode", "~> 3.1"`) instead of leaving a host with `cannot load such file`. Same contract as the optional npm peers in `package.json`. Black on white with the spec's four-module quiet zone, neither configurable: a scanner reads dark-on-light, so theme colours would leave the code unreadable under a dark theme while still looking like a QR code. The SVG carries a `viewBox`, so `class: 'w-full h-auto'` overrides `size:`; `role="img"` plus an `aria-label` that defaults to the generic `bali_view.qr_code.label` ("QR code" / "Código QR") and takes a `label:` for the context the markup does not supply.

## [v3.1.0.beta.2] - 2026-08-06

### Added

- **Guide: filtering on derived attributes (`docs/guides/derived-filters.md`)** (#642). How to
  filter by a value that exists only in Ruby — a computed status, a health traffic light, an
  accent-folded name — without leaving Ransack: declare a `ransacker` over a SQL expression or a
  cached column and the attribute joins the Filters popover as a first-class citizen (operators,
  AND/OR groups, persistence, saved views), with no new Bali API. Documents the two worked
  patterns that resolved the motivating real-world case, the pagination anti-pattern they avoid
  (filtering in Ruby after `pagy` breaks the count and the summary), why the popover cannot host
  non-Ransack params (its OR groups resolve in SQL), and the honest host-side escape hatch for a
  value that truly cannot reach SQL. Cross-linked from the components guide and the
  `filterform-datatable` skill. Closes #642 in favor of this pattern; to be reopened only if a
  derived attribute that can be neither expressed in SQL nor cached in a column shows up.
- **`Bali::WorkflowSteps` — steps of a flow with a verdict per step (#716).** Neither `Stepper` (a daisyUI wizard by index: one `current:`, per-step look derived from position) nor `Timeline` (chronological) could tell an approval chain where step 2 was rejected while step 4 is still pending — so gc hand-rolls this layout twice, almost line for line. New vertical component: `with_step(title:, state:, assignee:, date:, number:)` plus a free content block for the comment; six states (`:success`, `:error`, `:warning`, `:current` with ring emphasis, `:pending`, `:skipped`) validated with the same machinery as every `color:` keyword. The connector under each circle takes the state of the **next** step — computed by the component, not the caller — and auto-numbering counts the real route only: a `:skipped` step renders muted with a dash and consumes no position (an explicit `number:` always wins). Structure lives in `@layer components` (`workflow_steps/index.css`), so host utilities on the template win without `!`; the connector spans the row's full height, so long comments cannot break it — the spot where the hand-rolled versions suffer. The horizontal "quick flow" variant and the decision-form pattern docs ship separately.

- **`Bali::Tag` accepts `icon:`, and the enum-badge pattern gets its sugar and its recipe** (#711):
  - `Bali::Tag::Component` takes an `icon:` keyword (glyph before the text, drawn at the pill's own font-size so it fits every badge size — a default 16px icon is as tall as the whole `badge-xs` pill) and a `with_icon` slot that takes `Bali::Icon` options and wins over the keyword. This replaces the `safe_join`-an-icon-into-`text:` hack repeated across host helpers.
  - `Bali::Tag.for(value, map:, i18n_scope:, default:, **tag_options)` — the enum sugar: a host-owned `value => color/options` map (entries are a bare color name or a hash of Tag options; `text:` overrides the label) plus i18n label resolution, returning a component ready for `render`. An unmapped value raises unless `default:` is given — a new domain state must be mapped, not rendered blank.
  - `Bali::Status.for(...)` — the mirror for workflow states: the same map shape builds the whole `options:` array (entry `label:` overrides), so one map also powers the editable panel; `form:`, `size:`, `id:`, etc. pass through.
  - `Bali::Status.palette(name)` — the fixed 12-color workflow palette is now public API: returns the `{ bg:, fg: }` hex pair (raising on an unknown name) for painting non-pill things (a Gantt bar) in the same colour as the pill. Public means frozen: changing a hex is a breaking change from here on.
  - New guide `docs/guides/enum-badges.md` with the canonical recipe ("the map lives in a host helper") and the official Tag vs Status criterion: Tag for categories/priorities that follow the theme, Status for workflow states on the fixed theme-independent palette.
- **ViewSwitch: `icon:` is now optional and `mode: :selector` covers data-slice selectors** (#729). `with_view` no longer requires an icon — a selector that slices the data shown ("12 months", "Optimistic") is text-only by design. `mode:` on the component distinguishes the two jobs the control does: `:navigation` (default, unchanged — active view announces `aria-current="page"`) for sibling views of the same content, and `:selector` (active view announces `aria-current="true"`, "the current item of a set") for controls that slice the data (year, scenario, months window). The views stay real links in both modes; `aria-pressed` was deliberately *not* reintroduced — browsers discard it on `role=link`, which is the measured a11y bug v3 removed.
- **Card, StatCard and DashboardPage stats are clickable via `href:`** (#729). `Bali::Card` gains `href:` — the root element renders as `<a class="card">` with a `transition-shadow hover:shadow-md` affordance; `Bali::StatCard` propagates it (KPI drill-down without the `link_to` wrapper), and `DashboardPage#with_stat` gains `href:` so a stat inherits it. With `href:` the card's content must not contain links or buttons (interactive content inside an `<a>` is invalid HTML) — StatCard's `footer` included.
- **Dropdown items (and any Link/Button) can open a pre-rendered "local" modal or drawer** (#641). `with_item(name: 'Edit health', modal: { id: 'health-modal', local: true })` — likewise `drawer:` — opens an overlay that is already on the page, by name and with no fetch: the new `modal#openLocal` / `drawer#openLocal` action dispatches the open event addressed with the id and no content, so the overlay keeps its server-rendered content. Without an `href:` the item renders as a real `<button>` (an `<a>` with no href is not even focusable); the same `modal: { id:, local: true }` sugar lands on `Bali::Link::Component` (riding on the href as fallback navigation) and on `Bali::Button::Component` (local mode only — a button has no href to fetch). The `id:` is mandatory in local mode and the components raise without it: an open event naming no overlay is a broadcast, and a broadcast opens every shared overlay on the page (#854).
  - `Bali::Modal::Component` now takes `shared: false` (requires an explicit `id:`), mirroring the drawer's keyword: the dialog renders its own controller instance and answers only open events that name it — under the page-level controller the `template` target is whichever dialog comes first in the DOM, so an addressed open was compared against the wrong id and dropped.
  - `Bali::Link`'s `modal: { id: }` / `drawer: { id: }` (without `local:`) now emits `data-modal-id` / `data-drawer-id` for the addressed *remote* open — the attribute the controller always read but every call site had to write by hand.
  - Docs: item-shape table in `components.md`, "Opening an overlay by name, and the local mode" in `docs/guides/overlays-and-the-top-layer.md`, `local_overlays` Lookbook preview (with a decoy modal so the #854 regression stays measurable) and a Cypress spec asserting only the named dialog enters the top layer.
- **`Bali::Topbar::UserMenu` — the prefabricated user dropdown** (#713). A preset of
  `Bali::Dropdown` (the ActionsDropdown move), so keyboard navigation, Escape,
  `aria-expanded` and `popover:` come with it — everything the hand-rolled
  `<details class="dropdown">` menus in the apps never had. Trigger: `Bali::Avatar` with
  `name:` (photo via `avatar_url:`, or derived initials with a deterministic colour, #712),
  the name hidden on mobile, and a chevron. Panel: a non-actionable name/email header
  (`Dropdown::Title`), the host's `with_item`s, then sign-out. `sign_out:` has **no default
  route** — the item only renders when the call site passes `sign_out: { href: ... }`, so
  the gem stays uncoupled from bali-auth; `method:` defaults to `:delete` and submits a
  real form (`button_to`) that cannot degrade to a GET without JavaScript, with the
  delete-confirm dialog off (pass `confirm:` to opt in). New `bali_view.topbar.user_menu.*`
  locales (en/es).
- **`Bali::Topbar::IconAction` — one icon button for the Topbar's `with_action` slot**
  (#713). The notification bell packaged: a `<button>` (or `<a>` with `href:`) that
  requires an accessible `label:`, with an optional badge — `badge: true` draws the dot, a
  number draws a count pill (`Bali::Tag`), and `badge_id:` names the indicator `<span>` so
  the host can `turbo_stream.replace` it (with `badge_id:` alone the span renders empty
  and hidden, ready for a stream to light up). The component brings no polling and no
  channel — only the target. The Topbar/AppLayout previews and the dummy admin topbar now
  compose both components instead of hand-rolling the markup.
- **FormBuilder: `error:` option — external errors per field** (#723). Every field group now
  accepts `error:` (String, Array, or nil/false for "nothing"), carrying a message that never
  lived in `object.errors` — a rodauth view rendering `form_with url:` with no object, or any
  non-ActiveModel validator. The explicit error rides the exact plumbing model errors already
  use: the `.text-error` message paragraph, the `aria-invalid`/`aria-describedby` pair, and the
  family's `*-error` class on the control. When the model also has errors on the field the two
  sources join rather than replace, explicit first. On the two-hash families (`select_*`,
  `slim_select_*`, `time_zone_select_*`, `radio_*`) it is a group option and works from either
  hash. A new contract test (`external_error_option_test.rb`) makes every group helper declare
  its outcome — full dress, message only, or silent — so no family can drift out unnoticed.
- **FormBuilder: `size:` density variants — foundation** (#723). On the text-input families,
  `size:` with a Symbol (`:xs`/`:sm`/`:md`/`:lg`/`:xl`) now renders the daisyUI `input-*`
  density class instead of the attribute; an Integer — or a String, which is what `size: "4"`
  always meant — keeps meaning the HTML `size` attribute and passes through untouched, and an
  unknown Symbol raises instead of leaking into the markup (the contract `submit_field`/
  `submit_group` already enforced through `ButtonTaxonomy`, now asserted for both mechanisms).
  The per-family maps (`select-*`, `textarea-*`, `file-input-*`, `range-*`) build on this
  foundation in a follow-up PR.

- **`Bali::Gantt` — phase 2: the GanttFlow React island ships in the npm package** (#705). The ~2,600-line interactive Gantt (React Flow canvas, columnar table, toolbar, minimap, footer, optimistic editing with server reconcile) migrated from afal-apps into `app/components/bali/gantt/`, decoupled from TDFlow and mounted through the react-island base (#703) — never a second Stimulus Application:
  - **npm subpaths** `bali-view-components/gantt` (+ `gantt-entry`, `gantt-loader`), reusing the `./gantt` name removed in 3.0 with zero consumers (D13), in exact symmetry with `./block-editor`. New optional peer: `@xyflow/react >= 12`. The dedicated entry emits the island's CSS (React Flow's stylesheet plus `flow.css`); the main bundle stays React-free.
  - **Parametrized against the phase-1 contract**: the island consumes `{ window (optional, derived when absent), groups[], items[], dependencies[], critical_ids[] }` — the renames (`stages→groups`, `tasks→items`, `title→name`, `parent_*→parent_id`) live in the host serializer (D19). `catalogs:` (`{ statuses: [{value,label,color}], priorities: [{value,label,hue}] }`, D11) replaces the hardcoded TDFlow status/priority constants; the flat `i18n` prop served from `bali_view.gantt.island.*` via `Bali::Gantt::Translations.island` (D12) replaces ~43 hardcoded Spanish strings, with English defaults in the bundle; the zoom persists under a namespaced `gantt_zoom` param, configurable via `zoomParam` (D14); `editable`/`manageable` gate moving/resizing vs. rewriting dependency topology.
  - **`milestone:` items render as diamonds** in the island (D6 parity with `:static`) and **critical dependency edges are now visibly critical**: the `.critical` className the model always emitted gained its one CSS rule — `stroke: var(--color-error)` (D10; it was dead code in afal-apps).
  - **Full editing in the dummy** (D15/D17): `Admin::Projects::SchedulesController`/`DependenciesController` are the executable reference of the mutation contract (PATCH item / POST-DELETE dependency → always the complete document; 422 `{errors}` → rollback; 404 → re-GET), backed by `TaskDependency` (cycle/self-link validation) and a naive longest-chain critical path in `ProjectGantt`. The Lookbook previews `bali/gantt/island` (editable, seeded project) and `island_readonly` (toy data) exercise the island end-to-end; `/admin/projects/:id?view=timeline` keeps the `:static` render and is fully wired for phase 3 (#719) to flip `mode: :interactive`. Cypress covers mount-on-host-Stimulus, the namespaced zoom, collapse, color-by, critical edges, milestones and the drag → PATCH → reconcile loop.
- **`Bali::Gantt` — phase 1: the shared data contract and the server-rendered `:static` mode** (#704). One component, two renderers; this phase ships the foundation the React island (phases 2-3, #705/#719) will plug into:
  - `Bali::Gantt::Data` parses and validates the frozen contract — `{ window, groups[], items[], dependencies[], critical_ids[] }` with two-level group/item nesting (`parent_id`), ISO8601 dates, and the optional fields the real island already consumes: `assignee`, `percent_complete`, `slack_days`, `priority`, plus `milestone:` (rendered as a diamond) and `href`. Single-date items draw as minimum-width bars, inverted ranges clamp to their start, and structural errors raise instead of silently dropping bars. A frozen sample of `TDFlow::GanttSerializer` output validates the rename mapping (`test/fixtures/gantt/`).
  - `Bali::Gantt::TimeScale` — one day-based coordinate system shared with the future island (`px_per_day` 24/8/2 for day/week/month, exactly `ZoomControls.jsx`), `:auto` density picked from the window span, minimum bar width, inclusive ends, clipped calendar ticks/bands and the today marker.
  - `Bali::Gantt::Colors` — the exact `color-mix`/oklch formulas of the island's `ganttColors.js` (verbatim-asserted in tests) so both renderers are visually identical; default status map plus support for host status catalogs.
  - `Bali::Gantt::Component` `mode: :static` — sticky two-tier header, collapsible `<details>` groups (with their own rollup bars), today line, grid, `color_by: :status/:none`, zoom by links on a namespaced `gantt_zoom` param, `group_label:`, an announced `limit:` cap (never silent) and a "No dates" section. This closes the `color_by:` promise made to #667. `mode: :interactive` is part of the signature already and raises with a clear message until phase 3.
  - Structural `--gantt-*` tokens in `@layer components`, `bali_view.gantt.*` locales (en/es), Lookbook previews, and a full dummy reference: `/admin/projects/:id?view=timeline` renders the timeline from seeded schedule data through `ProjectGantt`, a host-side reference implementation of the contract.
- **`Bali::Timeline` learns the tracking look: `compact:`, `state:`, `timestamp:` and a clickable box** (#714). What three apps hand-rolled with raw daisyUI timelines (custody chains, itineraries, patrol logs) is now the component:
  - `compact: true` on the container adds daisyUI's `timeline-compact`: one column, every content box on the end side (`position:` no longer alternates there).
  - `with_item(state: :done | :current | :pending)` is sugar over `icon:`/`color:`: `:done` renders a `circle-check` primary marker, `:current` a `circle-dot` primary marker, and `:pending` the plain circle with a muted heading. Explicit `icon:`/`color:` win (`state: :done, color: :success` for the green check); an unknown state raises with the valid names.
  - `timestamp:` (a string, or anything `l`-localizable) renders muted on the free side of the line — or as a line inside the box when compact, the custody-chain layout. A `with_timestamp` slot replaces the keyword when the metadata needs markup (`<time>`, a tooltip).
  - `href:` renders the content box as an `<a>` with hover feedback, same tag decision as `Bali::Tag`.
  - The "tracking" preset (event + date + author) is documented in the component guide and has its own Lookbook preview.

### Changed

- `Bali::Timeline`: the line below an item now takes the colour of the item that *follows* it, so a coloured line reads as "travelled this far" — the exact look the hand-rolled tracking timelines draw. Only timelines whose consecutive items mix different explicit colours render differently (the boundary used to be half each colour); uniform and default-coloured timelines are untouched. The line below the last item keeps its own colour. (#714)
- `Bali::Timeline::Item` extra options now land on the content box as HTML attributes. They were documented as forwarded but silently dropped, so no existing markup changes — `data: { action: ... }` on an item simply starts working, which is what makes the box clickable without an `href:`. (#714)

### Changed

- **Five icon names stop being shadowed and now draw their real Lucide glyph** (#902). `trash`, `cog`, `expand`, `indent` and `outdent` were `LucideMapping` keys redirecting to a different drawing (`trash-2`, `settings`, `maximize`, `indent-increase`, `indent-decrease`), which made the glyph lucide.dev shows for those names unreachable — silently. The entries are removed; each name keeps resolving through the direct-Lucide step. Write the old target name to keep the previous drawing — the before/after table is in the [v3 → v3.1 migration guide](docs/guides/migration-v3-to-v31.md) (and, because it reaches v1/v2 hosts on their jump, in the [v2 → v3 guide](docs/guides/migration-v2-to-v3.md)). Measured across all pinned v3 hosts: zero call sites of the five. Related, in the same change:
  - `check-circle => circle-check`, `edit => pencil` and `plus-circle => circle-plus` stay mapped as documented exceptions — their "honest" spellings are deprecated Lucide aliases (a legacy glyph, and a name whose real rename is `square-pen`), so removal would make drawings worse, not truer. The shadowing test freezes the surviving set and pins the removed names to the direct-Lucide step.
  - The 60 identity entries (`"check" => "check"`, …) are gone — verified no-op, the direct-Lucide step resolves every one of them identically. "Did you mean" suggestions now draw from the full Lucide set instead of the mapping's keys, so `arrow_left` still suggests `arrow-left` (and any Lucide name typo gets suggestions, which it previously did not).
  - `Bali::DeleteLink`'s default icon is now spelled `trash-2` internally — same drawing as always.

### Changed

- **Announced (v3.1 block): a Card given `href:` changes its root element, and `DashboardPage::Stat` grows from five members to six** (#729). Opt-in per call site — without `href:` the markup is byte-identical — but adopting it breaks host test selectors that assert `div.card` or the old `a > div.card` wrapper shape, and positional construction of the `Stat` Data class outside Bali now raises. See [the v3.0 → v3.1 migration guide](docs/guides/migration-v3-to-v31.md#card-root-becomes-an-a-when-given-href-729).

### Changed

- **Dropdown/ActionsDropdown items with `method: :post/:patch/:put` are now real `button_to` forms** (#641 — announced change, see `docs/guides/migration-v3-to-v31.md`). They rendered `<a data-turbo-method>`, which degrades to a GET *navigation* without Turbo and announces as a link while mutating state; they now render `<form class="contents" method="post">` + `<button type="submit">` styled as the item — the exact shape the `:delete` item has had since #829, form out of the box tree, `_method` override for `:patch`/`:put`, `data:` still landing on the button. Measured blast radius: 6 call sites across all consuming apps (1 in afal-apps on v3 today, 5 in a v2-locked host), behaviour identical for all of them. Plain `Bali::Link` with `method:` outside a dropdown keeps `data-turbo-method`.
- **`Bali::Kanban` learns the board-level anatomy real boards use** (#643). The API is deliberately board-level — the reference boards in afal-apps proved the height and the scroll live on the board, not on each column:
  - `layout:` on the board — `:grid` (default, unchanged: caps at 4 columns) or `:flow`, a single horizontally scrolling row with `w-72` columns, which is what a 5+ column board needs.
  - `height:` on the board (opt-in, default `nil`) — `:viewport` caps the board to `calc(100vh - var(--bali-kanban-offset, 17rem))` (override the CSS variable to match the host's header chrome) and any string is taken as a height utility class. On a bounded board each column's card list scrolls internally; there is no separate `scrollable:` knob and no per-column `max_height:`.
  - Columns are now `flex flex-col min-h-0` with the card list as `flex-1 overflow-y-auto`, so the list (not the page) is what scrolls and the whole body of a column is a drop target.
  - **Empty columns keep a visible drop area**: a 100px floor with a dashed border, driven by CSS `:has()` in the new `kanban/index.css` (`@layer components`) rather than a render-time `cards.empty?` flag — it appears live when the last card is dragged out and yields to SortableJS's ghost while a drag hovers.
  - `with_column` accepts `disabled: true`, forwarded to the underlying SortableList (the option existed there but the column never passed it through).
  - The Kanban section of `docs/guides/components.md` gained a "Wiring the drop PATCH" guide with the Rails side of the contract: member route, 1-based `resource[position]` + `list_param_name` params, and when to answer with `:html` vs `:turbo_stream`.
  - New Lookbook preview `kanban/scrollable_board` (flow layout, viewport height, an empty column, a disabled column) and a Cypress spec covering per-column scroll, the live empty-column affordance and the PATCH payload.
- **The AFAL brand theme ships in the gem: `css/themes/afal.css`** (#718). Canonical copy
  of the `[data-theme="afal"]` block that gobierno-corporativo, afal-apps, identity and
  opina carried byte-identically in their own CSS — same plain unlayered `[data-theme]`
  format as `costa-norte.css`, importable via
  `@import "bali-view-components/css/themes/afal.css"` with no `package.json` change (the
  `./css/themes/*.css` export wildcard already covered it). Hosts should delete their
  local block in the same commit that adds the import — see the
  [v3 → v3.1 migration guide](docs/guides/migration-v3-to-v31.md). Note for adopters:
  from now on a color change in this file propagates to every host on its next bump;
  such changes will always be announced as a visual change in this file.
- **A `css/themes/afal-dark.css` DRAFT** (#718). All four AFAL hosts have long declared
  `afal-dark` in their daisyUI plugin config without any definition existing anywhere;
  this is the first actual design — derived from the light theme (same gray ramp
  inverted, brand hues lifted one Tailwind step with `-950` content pairs, status colors
  unchanged, every pair measured >= 4.5:1 WCAG AA). **Experimental**: no app activates it
  and tokens may change before it is announced stable. Preview both themes in Lookbook
  under *Theme Sampler* (new `afal` and `afal_dark` previews with their own layouts).
- **Custom themes guide covers AFAL** (`docs/guides/custom-themes.md`): the adoption
  path, the phantom `themes: afal --default, afal-dark` plugin note, and the
  `@custom-variant dark` extension `afal-dark` needs for `dark:` utilities to fire.
- **Theme regression tests**: every file in `app/assets/stylesheets/bali/themes/` is
  asserted complete (the 26 required variables plus `color-scheme` and the
  `[data-theme]` selector matching its filename), and the ThemeSampler previews get a
  request test so a broken theme preview fails the build.

### Fixed

- **`docs/guides/installation.md` documented an incomplete `@source` glob** (#718): it
  scanned `*.{rb,erb}` but not `.js`, and some Tailwind classes are written from
  JavaScript (`modal/index.js` swaps a drawer's submit button for
  `loading loading-spinner loading-sm`), so the spinner rendered unstyled in apps that
  copied the documented glob. The canonical glob is now `*.{rb,erb,js}`, and the guide
  also documents the optional vendor/bundle glob that only matches on CI with a vendored
  bundle (and why a non-matching `@source` is harmless).

## [v3.1.0.beta.1] - 2026-08-05

### Added

- **Troubleshooting entry for the BlockNote <= 0.52.1 render loop (#908).** The BlockEditor guide (`docs/api/block-editor.md`) now documents the `Maximum update depth exceeded` console error: it appears while typing (or when closing a drawer/modal holding the editor) when a browser extension that rewrites the page's DOM (Dark Reader, Grammarly, page translators) is active, because BlockNote <= 0.52.1 node views do not ignore non-content mutations (TypeCellOS/BlockNote#2818, fixed upstream by #2912 — merged but not yet released). No data is lost; the `@blocknote/*` bump lands separately once upstream publishes a release containing the fix.
- **Stimulus utility controllers catalog.** New guide `docs/guides/controllers.md`
  (mirrored as a Lookbook guide page) documenting all 24 standalone controllers in
  `app/assets/javascripts/bali/controllers/` — Stimulus identifier, what each does, and a
  minimal markup example per controller — plus a "Do you have a local copy?" section
  listing the known per-app copies to delete or review, referenced from the migration
  guide. `docs/guides/javascript-integration.md` now links to the catalog instead of
  keeping its own partial table (it listed 12 of the 24, and still offered the deprecated
  `NotificationController`), and `scripts/check-controller-manifest.mjs` gained a fifth
  check: the build fails if a registered utility identifier is missing from the catalog
  or its Lookbook mirror. (#717)

### Changed

- Deleted the 15 stale `// TODO: Add tests (Issue: #NNN)` comments from the utility
  controllers — all 15 referenced issues (#136–#144, #154–#157, #225, #253) are closed on
  GitHub, so the comments only misled readers into thinking the work was still tracked.
  Two stale header comments were corrected along the way: `radio-buttons-group`'s example
  used a `radio-buttons-grouped` identifier that never connects, and `radio-toggle`'s used
  `data-toggle-radio-current-value` instead of `data-radio-toggle-current-value`. (#717)
### Added

- **New migration guide skeleton: `docs/guides/migration-v3-to-v31.md`.** Migration notes
  for the 3.1 line live in a new per-release document instead of growing the v2 → v3 guide.
  The skeleton states the upgrade policy — five announced markup/behaviour changes admitted
  as a block (#903, #641, #722, #729, #902) — and reserves one section per change; each
  section's details land with its PR.
- **`Bali::Tabs` tabs take a `count:` badge.** `with_tab(count: 12)` renders a `badge badge-sm` after the title, in both modes — navigation tabs (the scopes pattern: Mine / Team, statuses, the inbox counter case) and panel tabs. `nil` renders nothing; `0` renders, because an empty scope is information. A string works too (`"99+"`). The badge is not `aria-hidden`: the number belongs in the link's accessible name ("Mine 12"). (#722)
- **Navigation-mode tab links emit `data-turbo-action="advance"` by default.** A no-op on full-page visits (advance is already Turbo's default); inside a `turbo_frame` it promotes the visit to the URL, which is what makes URL-driven scope tabs addressable and back-button friendly. `turbo_action: false` omits the attribute; another symbol (e.g. `:replace`) passes through. Ignored in panel mode. (#722)

### Changed

- **`Bali::Tabs` navigation mode: the tab's `**options` now land on the `<a>`.** They used to be merged into the attributes of a panel `<div>` that navigation mode never renders, so they silently vanished — there was no way to put a `data:` attribute on a tab link. `class` composes with the tab classes instead of replacing them. Only a call site that passed options to an `href:` tab *and* relied on them being ignored changes behaviour; none exists among the pinned hosts. One of the five announced v3.1 changes — see [the migration guide](docs/guides/migration-v3-to-v31.md). (#722)
### Added

- **Avatar derives initials and a deterministic color from `name:`.** `Bali::Avatar::Component.new(name: 'Ana García López')` now renders an initials placeholder — first letter of the first and the last word ("AL", unicode-aware upcase; one word yields one letter) — over a background hashed from the name into the fixed `Bali::Status` palette minus `slate`/`gray`, rendered as an inline style: the same person gets the same color on every render, process and DaisyUI theme. The hash is the new `Bali::Utils::ColorCalculator#deterministic_color(seed)` (`Zlib.crc32`, not the per-process-randomized `String#hash`); collisions between names are expected and fine. `initials:` overrides the derivation, and images keep winning: picture slot > `src:` > manual `placeholder` slot (which keeps its static neutral background) > `name:`/`initials:`. With `name:` present the avatar also stops being invisible to assistive tech: initials avatars get `role="img"`, `aria-label` and `title` with the full name, and image avatars use it as the `alt` (an explicit `alt:` wins). Groundwork for `Topbar::UserMenu` (#713). (#712)
- **`Bali::DescriptionList::Component` — a set of label/value pairs in the component's own responsive grid** (#727). The middle ground between `Bali::LabelValue` (one pair the caller places) and `Bali::PropertiesTable` (one set read top to bottom as a table): `columns:` 1/2/3 with responsive collapse, `layout:` `:stacked` (default) or `:horizontal` (term and value side by side inside each cell), and `with_item(label:, value:)` accepting block content for rich values such as a `Bali::Tag`. Markup is one `<dl>` of `<div><dt/><dd/></div>` cells, and `dt`/`dd` reuse LabelValue's typography so the three options read as one family; the guide now carries the three-way comparison under DescriptionList.
### Fixed

- **SimpleFilters lost the listing URL's own query params on every submit.** A GET submit replaces the action's query string with the form's fields, so a host passing `url:` with params of its own (a scope such as `status=historico`) saw them silently dropped each time the simple form was applied — the "Clear" link preserved them (beta.6), the submit did not. The form now re-emits the non-filter query params of its `url:` as hidden fields with the exact semantics `Bali::Filters::Component` always had: `q`, `clear_filters`, `clear_search` and `saved_view` stay out, and on a key collision the explicit `preserved_params:` hash wins, so a host already passing the param by hand does not emit it twice. (Refs #725)

### Changed

- **Filters/SimpleFilters internal dedup — no rendered-output change for the full panel.** The preserved-params semantics above now live in one shared `Bali::Filters::PreservedParams` module; the `storage_id`/`persist_enabled?`/`persistence_toggle?` persistence trio both components copied is now the `Bali::Filters::Persistable` concern; and the AND/OR combinator divider the panel template carried twice (popover and inline branches) is the `Bali::Filters::CombinatorDivider::Component` subcomponent. (Refs #725)
### Added

- **`react-island`: the official React-island infrastructure** (#703). The block editor's mounting mechanics, extracted into a reusable module so new islands (the upcoming Gantt) do not re-implement them. One npm subpath, `bali-view-components/react-island`, exports `ReactIslandController` (a Stimulus base class: subclass and implement `loadComponent()`; the base handles `createRoot`, values→props, a built-in React ErrorBoundary, Turbo cache exclusion and unmount on disconnect), `registerIsland(name, Controller)` (the whole body of an island's bundler entry — registers on `window.Stimulus`, idempotently, never a second Application) and `startIslandLoader(name)` (main-bundle lazy loader driven by `<meta>` tags). The new `react_island_meta_tags(name, js:, css: nil)` helper publishes the digested bundle paths those metas carry; `block_editor_meta_tags` is now its block-editor spelling (same output, not deprecated). Errors from both phases (load and render) funnel through the configurable `ReactIslandController.onError` static hook, so a host plugs Sentry in once for every island without the gem depending on any tracker. Guide with the full wiring and the extraction criteria: `docs/api/react-island.md`; working toy island in the dummy app with Lookbook previews (`bali/react_island/*`) and a Cypress contract spec. `BlockEditorController` itself migrates to the base in a follow-up PR.
- **`Bali.engine_controller_concerns` — the official way for a host to teach its context to the engine's controllers.** `isolate_namespace` means `Bali::ApplicationController` inherits from `ActionController::Base`, not from the host's `ApplicationController`, so `current_user` and friends never existed inside the engine — every host worked around it by monkey-patching `Bali::SavedViewsController` from a `to_prepare` initializer, once per controller, once per app. Every module in the new array is now included into `Bali::ApplicationController` (and therefore into every engine controller at once) on each `to_prepare`, idempotently and surviving code reloads. The concern must stay passive — identity, not access: the gate remains the `Bali.*_authorize` lambdas. The new [Engines guide](docs/guides/engines.md) documents the `isolate_namespace` gotcha in one place, the authorize-lambdas doctrine, and the bali-auth recipe (`include BaliAuth::Authentication` + `allow_unauthenticated_access`). (#710)
- **`Bali::BlockNote::Text`, `Bali::BlockNote::Diff` and `Bali::BlockNote::Chunker` — pure-Ruby BlockNote content libs** (#708, PR 1 of 2). Ported from gobierno-corporativo's `Document::BlockNoteText` / `Document::ContentDiff` / `Document::Chunker` and generalized under the engine so every host shares one walker for BlockNote JSON:
  - `Text` extracts plain text from BlockNote block structures — inline `text` and `entityReference` nodes, table blocks in both the legacy `tableRow` and current `tableContent` shapes, nested children — and `Text.normalize` accepts Array/Hash/JSON-string content, unwrapping legacy v1 `blockGroup`/`blockContainer` layers.
  - `Diff` compares two contents at section level (`changed_sections` / `summary`, grouped by heading with an id-stripped structural fingerprint) and at block level (`annotated_blocks` marks each block `added`/`removed`/`modified`/`unchanged` by BlockNote UUID; modified blocks carry `_diff_spans` from a word-level LCS diff). Removed blocks and sections appear inline at their original position.
  - `Chunker` splits a document into heading-delimited chunks for search indexing / RAG (target 1600 chars, 300-char overlap, ~4 chars/token estimate). Embeddings and vector storage stay host-side on purpose — no pgvector in the engine.

  The libs live in `app/lib/` (autoloaded, no new eager-load path) and are deliberately free of ActiveSupport core extensions: they load and run under plain Ruby. New runtime dependency: `diff-lcs` (~> 1.5, MIT, no transitive deps) for the word-level spans. Entity-reference extraction, registry and controller arrive in PR 2.
- **Cypress coverage for `dynamic-fields-controller`** (#715 PR1, closes the TODO from #155).
  `cypress/e2e/dynamic-fields-controller.cy.js` freezes the controller's current JS contract
  before the #715 feature work touches it: `addFields` clones the `<template>` replacing the
  `new_record` placeholder with a numeric child index, `removeFields` hides the row (it stays
  in the DOM), sets `.destroy-flag` to `true` and strips the non-hidden form elements while
  keeping the hidden ones, `moveUp`/`moveDown` swap rows and renumber every `[data-position]`
  input (and are no-ops at the edges), and the `remove-duplicates` mode drops already-selected
  options from the cloned template and disables the add button at maximum size — on `connect()`
  too — re-enabling it when a row is removed. Two new Lookbook previews back the parts the Ruby
  helper does not emit yet (`sortable`, `remove_duplicates`), wired by hand the way host apps
  do today; the add/remove specs run against the existing `default`/`empty` previews.

### Dependencies

- Updated daisyUI to 5.7.16 in the dummy app. The package's peer range (`>=5.7.0`) is unchanged.

## [v3.0.0] - 2026-08-05

**v3 goes stable.** Same code as `v3.0.0.beta.6` — this release promotes the beta line to
the stable channel: `3.0` merges into `main`, `main` becomes the v3 line, and the next
line of work continues on the `3.1` branch (CI now covers `main` and `3.1`). Everything
the v3 line changed since `v2.x` is recorded in the `v3.0.0.beta.N` entries below.
Upgrading from v2: read the [migration guide](docs/guides/migration-v2-to-v3.md); how the
channels work is in [Release channels](docs/guides/release-channels.md).

## [v3.0.0.beta.6] - 2026-08-05

### Fixed

- **El link "Limpiar" de los filtros simples no limpiaba nada con la persistencia encendida.** Navegaba a la URL pelada, y para el server eso es indistinguible de "no vino ningún filtro" — con `persist_enabled` ese es justo el caso que RESTAURA lo guardado, así que el listado le devolvía al usuario el filtro que acababa de limpiar, con el select repoblado. Ahora manda `clear_filters=true`, el único param que dispara el borrado de la caché (`Rails.cache.delete(cache_key)`); las otras dos rutas de limpieza (`Filters::AppliedTags#clear_all_url` y `clearFiltersAndClose` del JS) ya lo mandaban y ésta se había quedado afuera. El param se AGREGA al query string en vez de reemplazarlo, así una `url:` con params propios del host los conserva.

  Medido en un host, sobre cuatro listados y con caché real: filtrar dejaba 9 de 69 elementos y limpiar seguía mostrando 9; ahora vuelve a 69. Con la persistencia apagada el link ya funcionaba, que es lo que hacía tan fácil no verlo.

  Los dos tests que cubrían este link asertaban su href contra la URL pelada — fijaban el bug como contrato y habrían seguido en verde para siempre. Se corrigen, y el caso pasa a probarse SIGUIENDO el link: el href renderizado se parsea y se le entrega al `FilterForm` igual que haría el server con el request del click, asertando el estado resultante del listado y que la caché quedó borrada, no la forma de la URL.

## [v3.0.0.beta.5] - 2026-08-04

### Changed

- **`Bali::Command` renders its own trigger; the slot replaces it, and `trigger: false` removes it.** Every call site that rendered a visible trigger — both palette previews, the AppLayout navbar preview and the dummy admin topbar — hand-rolled the same search-well button, which is the clearest sign the component was missing a default. It now renders that well itself (search icon + `trigger_label:` + the `shortcut_label` `kbd` hint marked `aria-hidden`, `aria-haspopup="dialog"`, its own themed focus-visible ring), sized by the component's `class:`; `with_trigger` replaces it for shapes the default cannot be. `trigger_label:` is independent of `placeholder:` on purpose — the trigger is usually shorter than the input's invitation — and ships in en and es (`bali_view.command.trigger_label`).

  **This changes rendered output for one existing shape**: a palette mounted with no `with_trigger` at all — opened only via ⌘K or `bali:command:open`, the way the dummy's z-stack page mounts it — would now grow a visible search well. `trigger: false` is the named opt-out, and the migration guide carries the note.

  The default is deliberately **not** a `.btn`: closing the palette with Escape returns focus to the trigger, and daisyUI's 2px focus-visible outline around a bordered button reads as a double border — measured on the AppLayout navbar preview, whose `btn-soft` trigger showed exactly that (1px border + 2px outline at 2px offset). A filled well carries no border of its own — and it declares its own `focus-visible` outline, because dropping `.btn` also dropped daisyUI's ring and the browser's fallback ring does not follow the theme.

  The palette's `<dialog>` also takes `aria-label` from `placeholder:` — it announced as an unnamed dialog before.

- **The AppLayout reference scenario for "sidebar + account bar" is `with_topbar` now, built on `Bali::Topbar`.** The old "Navbar + Sidebar + Content" preview modelled that layout with a `Navbar` — a `<nav>` landmark carrying no navigation, since the sidebar owns every destination — and needed three overrides (`min-h-0 bali-chrome-height`, `fullscreen:`, `shadow: false`) to sit on the chrome line `Topbar` sits on by construction. The scenario now renders `Topbar` (banner landmark, chrome-height shared with the SideMenu's brand row, its own `lg:hidden` hamburger — so AppLayout's default mobile row is no longer needed), with the Command palette in its `search` zone. "Navbar + Content" remains the scenario for the layout where the top bar IS the navigation, and `docs/guides/components.md` now carries the which-to-choose note. The `with_navbar` **slot** on AppLayout is unchanged — only the preview scenario moved.

- **The `actions_dropdown/with_custom_trigger` preview stops drawing two borders.** It nested its own `<button class="btn btn-outline">` inside the trigger slot, but the slot already renders `Dropdown::Trigger` — a `.btn`-dressed `div[role="button"][tabindex="0"]` carrying the wiring — so the preview painted two bordered boxes and offered two tab stops. Measured before/after: 2 `.btn` boxes → 1, 2 tab stops → 1, wiring intact and the menu still opens. The preview now shows the intended shape (`with_trigger(variant: :outline, class: 'btn-sm') { 'Actions ▾' }`), and its notes say why nesting a second button is the wrong one — the reference implementation is what hosts copy.

### Fixed

- **The pagination summary no longer says "of 1 items" — `item_name:` pluralizes.** (#909) `PagyAdapter#summary` already passed `count:` to `I18n.t`, but the key is a plain string and `item_name` was interpolated exactly as given, invariant with the count. The adapter now resolves it by type: a **Symbol** is an i18n key resolved with `count:` (Rails' full CLDR plural rules, for locales beyond one/other), a **Hash** picks `one:`/`other:` by count with no locale file needed, a **String** stays verbatim — the behaviour every existing call site already has — and the gem's `default_item_name` becomes a plural hash in both locales, so the default pluralizes too. One method covers `PaginationFooter` and `DataTable`, which only carry the value through.
- **The SlimSelect placeholder finally speaks the host's language.** (#910) The other six SlimSelect texts already resolve through `bali_view.form_builder.slim_select.*`; the placeholder was the odd one out — without `html: { placeholder: }` the wrapper emitted no data-attribute, so the Stimulus controller's English default ("Select value") won on every call site, whatever the host's locale. The wrapper now emits the translated placeholder as the default ("Selecciona una opción" in es); `html: { placeholder: }` keeps priority, so no existing call site changes.

## [v3.0.0.beta.4] - 2026-08-04

### Added

- **`comments: { threads: [...] }` seeds a `BlockEditor` whose comments do not persist**, so a demo or a preview can open with threads already in the sidebar. Ignored when `url:` is given — there the REST store fetches the list and owns it, so a seed would be gone on the first poll.

### Changed

- **Dependencies move to current: daisyUI `5.7.15`, `tailwindcss-ruby` 4.3.3, `csv` 3.3.6, `simplecov` 1.0.3.** The same bumps Dependabot has open against `main` (#765–#767), applied to the `3.0` line directly — plus daisyUI to its actual latest (the `main` PR stops at 5.7.7). daisyUI is the one with surface: it is the peer every component's CSS is written against, so the dummy pin is what the suite and Cypress actually exercise. `>= 5.7.0` stays the declared peer floor; nothing in 5.7.x moved under us — measured by the suite and the full Cypress run on the rebuilt output.

- **`f.submit` / `submit_field` / `submit_group` validate through `Bali::ButtonTaxonomy`.** The FormBuilder's submit button kept the last private button table in the library, and with it the exact failure mode v3 set out to remove: `variant: :info`, `:neutral` or `:link` rendered a colourless `.btn` in silence, `size:` stopped at `:lg`, and `style: :outline` — not being an option the helper knew — leaked onto the element as an inline `style="outline"` attribute. The submit now composes and validates through the same table as Button, Link and DeleteLink: the missing variants and `:xl` render, `style:` means the fill, and an unknown value raises `ArgumentError` naming the replacement. A call site passing a value outside the table — silently colourless until now — raises at render; that is the point, and the reason this lands before v3.0.0 rather than after it. One asymmetry to know: `style:` is a Bali option on the submit family now, so an inline CSS `style:` on a submit — a passthrough HTML attribute until this release, and still one on every other field family — raises instead of rendering.
- **`icon: "grid"` and `icon: "file-signature"` draw the glyphs those names mean on lucide.dev.** Both were keys in the legacy-name map pointing at a different drawing (`grid-2x2`, `file-pen`), and the map is consulted before the name is tried as a real Lucide icon — so the honest spelling of two current Lucide names was unreachable, silently. The two entries are gone; write `grid-2x2` / `file-pen` where the old drawing was the point — the library's own previews and the dummy app did exactly that, since the 2x2 quadrant is what a cards toggle means. The eight remaining keys that shadow a current Lucide name are now frozen by test: measured SVG against SVG, only `plus-circle` still draws the same thing as its target; the other seven (`check-circle`, `cog`, `edit`, `expand`, `indent`, `outdent`, `trash`) redirect to a genuinely different glyph, and #902 tracks deciding each of them.
- **`lucide-rails` is capped at `< 0.8`.** Icon resolution's direct-name step and several legacy spellings in host apps ride the alias SVGs lucide-rails still ships; an uncapped bump that drops them turns those names into `IconNotAvailable` — a 500 — with no change on the host's side. The cap makes that bump a deliberate act: raise it only after revalidating the mapping and the alias set against the new version.

### Fixed

- **The `block_editor/with_comments` preview opens with comments in it.** It rendered zero threads, which is not cosmetic: it is what made #832 — a thread card wider than the sidebar holding it — invisible. Reproducing that needed a comment created by hand through the UI first, and the preview sweep counted the page as a 200 either way. A preview that does not exercise what it announces covers nothing.

  A comment lives in **two** places and needs both to be a real one: a thread in the store, and a `comment` mark on the text it anchors to. Seeding only the store gets threads into the sidebar, each labelled "Original content deleted" — measured — because nothing in the document points at them.

  The mark cannot travel in the blocks array `initial_content` usually takes: BlockNote's comment mark declares `blocknoteIgnore`, so the block serializer skips it by design and no array of blocks can carry one. It travels in the **other** shape `initial_content` already accepts — ProseMirror JSON, the `{ type: "doc" }` form the component detects and loads through `setContent` precisely because it preserves comment marks. The preview now passes that shape, with a focused document instead of the shared showcase content.

  Two threads, because the sidebar's width is what breaks: a short one, and one whose comment carries a URL with nothing to break on. Measured after the change: 2 threads, 2 marks, 0 orphans, and the sidebar's `scrollWidth` equal to its `clientWidth`. Cypress now covers all of it, so #832 stays covered without anyone typing a comment first.

## [v3.0.0.beta.3] - 2026-08-03

### Fixed

- **A page morph can no longer strand an open `Modal` or `Drawer` in the top layer, leaving the page inert with no way out.** Idiomorph writes every attribute the new node carries and removes every one the old node has that the new one does not; the markup a server sends for an open panel is a *closed* panel, so a morph strips both `open` and the open class. And removing `open` from a `<dialog>` opened with `showModal()` does not take it out of the top layer: the document stays inert, the UA simply stops painting the panel, and `close()` returns early on a dialog with no `open` attribute — without throwing. Nothing was left that could free the page.

  Measured on a bare `<dialog>`, step by step: after `showModal()`, `:modal` is true and the point over a page button hits the dialog; after removing `open`, `:modal` is **still true** and `elementFromPoint` over that button returns `HTML`; `close()` there changes nothing. Put the attribute back and `close()` drops `:modal` to false and the page answers the mouse again.

  Both halves are fixed. `ModalController` now cancels `turbo:before-morph-element` for its own panel while that panel is open — checking the open class as well as `dialog.open`, since the class is all that holds the panel open in the fallback where `showModal()` was unavailable, and listening on `document` because the panel and the controller element are often different subtrees. Cancelling the element rather than the finer `turbo:before-morph-attribute` is deliberate: the morph also overwrites `class`, so saving `open` alone would leave the panel in the top layer without the class that shows it. Separately, `_hideOverlay` gives the attribute back before closing when it finds a panel that is `:modal` without being `open`, which recovers a panel that was already stranded — prevention only covers the panels a controller can see at the moment of the morph.

  `DrawerController extends ModalController`, so both overlays are covered by the one change. A closed panel still morphs normally.
- **"Remember filters" covers the simple filters, not just the quick search.** The marker was never dead — it governs the search box — and that made it worse than if it had been: the user turns it on, comes back to the listing with a clean URL, and the search returns while their selects do not. Nothing in the UI tells apart a control that is remembered from one that is not; both sit in the same toolbar row.

  The inconsistency was internal, which is what settled which side was wrong: a **saved view** over that same listing did restore them — `PAYLOAD_KEYS` has always listed `simple_filters` — so one component carried two definitions of "the filter state". A simple filter's value never becomes an ActiveModel attribute (it lives in `@q_params` and goes straight to Ransack), so `attributes.to_h` never carried it along by accident. The fix reuses the saved-view round trip instead of opening a second path: `active_simple_filters` writes, `apply_simple_filter_state` restores, `current_simple_filter_value` reads — one key throughout.

  The same gap made a shared link mean different things to different people, which is the half that bites without persistence being involved at all. `has_filter_params` did not count the simple filters, so a URL asking only for one fell into the *restore* branch and the cache outranked the URL. Measured on `/admin/studios` over `?q[country_eq]=USA`: **9 rows** with the persistence cookie on — a cached search the URL never mentions applied on top of it — against **10** with it off. They are counted now as an *origin* rather than a value, the same distinction `group_by` already makes: the SimpleFilters form submits every control it renders, so emptying a select arrives as `q[size_eq]=`, an explicit choice whose value is blank. Reading only the values would have made clearing a filter indistinguishable from asking for nothing, and the restore branch would have handed back the filter the user had just cleared.

  Clearing the search keeps them, too: `clearSearch` navigates dropping every `q[...]`, so the stored state is the only record left of what was selected.


- **`required:` on a `slim_select_*` field is no longer emitted, because it could block the submit without ever telling the user why.** The `<select>` SlimSelect wraps is clipped to 1×1 by `bali/slim_select.css` — correctly, since SlimSelect draws its own UI — and the browser cannot anchor a validation bubble to a box that size. Measured in the browser with only that control invalid: `reportValidity()` returns `false`, focus lands on the `<select>` (it is focusable, being clipped rather than `display: none`), and no message appears and nothing scrolls. The constraint was real and uncommunicable.

  `required_option_test.rb` already writes the contract this settles — the attribute reaches a control the browser validates, or it reaches nothing at all — and validated-but-unreportable is the in-between that test exists to forbid. `slim_select_group` moves to its `DROPS` side, next to the widgets over a hidden field, for a different reason than theirs: not "no element could carry it" but "the element that carries it cannot speak".

  It had to be stripped from **both** hashes, not just the element's: Rails' `select_content_tag` copies `:required`, `:multiple` and `:size` out of the select options and onto the element, so a top-level `required:` reached the `<select>` by a second route.

  **The blank option `required` was buying is kept.** Rails adds an empty `<option>` *as a consequence* of the field being required (`placeholder_required?`), so removing the attribute silently removed the blank too — and a nil value then painted as the first option in the list, a record with no priority opening its form with "Low" already chosen. The blank is now requested explicitly under Rails' own condition, and being a requested blank it becomes a real SlimSelect placeholder rather than a pickable row: measured on `/movies/new`, the widget reads "Select value" where before it read empty.

  This surfaced in v3 rather than earlier because v2 took the element's attributes from the second positional hash, so a top-level `required:` never reached the `<select>` at all. Unifying the extraction in #677 turned those decorative `required:` into real constraints. `time_zone_select_*` is **not** affected and keeps carrying `required`: it renders a plain, visible `<select>` with no SlimSelect wrapper, so the browser has somewhere to put the message.
- **A `required` `<textarea>` or `<select>` inside a `Modal` or `Drawer` form says why it blocked the submit, instead of nothing at all.** `submit` calls `event.preventDefault()` before validating, which cancels the browser's own interactive validation — so whatever the controller does *is* the report. What it did was walk `input` and call `reportValidity()` on each one, which left every other control type validated and reported to nobody: the button blocked the request with no message, no bubble, no console error and no focus anywhere. Measured on a form with three empty required fields (two `<textarea>`, one `<select>`): `submit` never fired, no request left, the three `invalid` events fired, and `document.activeElement` stayed on `BODY`.

  It now asks the **form** — `form.reportValidity()` — which validates every control the browser validates, focuses the first invalid one, scrolls to it and shows its message. The old loop was also wrong in the small: reporting control by control leaves the *last* bubble on screen rather than the first invalid field's.

  Wider than "inside a panel": `AppLayout` renders `<main>` with `data-controller="modal drawer"` by default, so a `submit_group(..., drawer: true)` on an ordinary page is captured by the same controller. The line dates from #430, so this is not a v3 regression. A new `drawer/required_fields` preview covers it.


- **Every control in the `DataTable` toolbar sits on the same line, not just the row's direct children.** Aligning the row itself fixed one level and left the other: the four groups that make it up align their own children, and the one holding the `SimpleFilters` block — which is twice the height of a single-line neighbour, because its captions sit above the controls — was centring them against it. Measured on `/admin/studios` at 2600px with the row already aligned: "Views" and the persistence marker sat level with the Filter button, while "Group by" and "Columns" sat **11px** above it. All four groups align to the end now; where every item is the same height the two alignments produce the same layout, so only that one group moves.

- **A listing with a search box and no filters says "Search" on its button, not "Filter".** With nothing declared to filter by, the only thing the button submits is the search term. The string already shipped — `bali_view.filters.submit_search`, used until now only as the full filter panel's search `aria-label` — so no new translation is involved.


- **The `data_table/with_simple_filters` preview survives a Studio with no status.** It answered 500 with `undefined method 'humanize' for nil` as soon as the database held one, which any record created from the drawer without picking a status leaves behind — the preview then stayed broken in that environment. The Size cell two lines below had the safe navigation all along. Seeded databases always set a status, which is why the preview sweep never saw it.
- **Opening Views, Columns or Group by inside the `DataTable` overflow menu no longer resizes the menu.** Measured on `/admin/studios` at 1900px, the `⋯` panel went from 320x176 to 320x338 — a popover growing under the pointer, with the child laid out in flow inside it.

  The container forced `position: static` on every `.dropdown-content` beneath it, and that was deliberate: a nested absolute dropdown positions against the container and leaves the viewport on a phone (measured, `left: -115px` at 375px), so stacking them as sections in flow is the sensible thing there. What changed is that the `⋯` used to *be* the mobile mode; since the valve started measuring the row it fires at any width, and the same rule was reaching the desktop. It is scoped to `max-sm` now — below the breakpoint nothing changes, above it the child floats over the panel as a popover inside a popover should.

- **The `DataTable` toolbar lines its controls up with each other.** `SimpleFilters` puts the caption *above* each control, so its block is twice the height of any single-line neighbour and wraps to two rows when the row tightens. With the toolbar centred, everything sharing that row aligned against the middle of the block rather than against its line of controls: measured on `/admin/studios` at 1900px, the `⋯` sat at y=226 and the Filter button — which lives on the block's last line — at y=264, **38px** below. The row aligns to the end now; where no item is taller than the others the two alignments are the same layout.

  Getting to zero took removing 4px of bottom padding from the filters row, and those 4px were doing something: the row declared `overflow-x-auto` at every width, which makes it a scroll container, and a scroll container clips at its padding box — the padding was the room for the Filter button's focus ring (`outline-width: 2px` at `outline-offset: 2px`). Above the breakpoint the row wraps and never scrolls, so the overflow goes back to `visible` there and the padding has nothing left to reserve. Below it nothing changes: the horizontal scroll and its gutter stay.


- **A transparent navbar is finally transparent, and shadowless.** `.navbar.is-transparent { @apply bg-transparent shadow-none }` had never had any effect. It lives in `@layer components`, and the `shadow-sm` the component put on the element itself is a utility, from a layer that outranks it — so with `is-transparent` on the element, box-shadow measured `0 1px 3px rgba(0,0,0,.1)` and the background measured `oklch(1 0 0)`, on `/lookbook/preview/bali/navbar/with_sidebar_burger?transparency=true`. The shadow half is fixed here, by moving the default into the sheet next to the state that overrides it, which is the rule the rest of the package follows. The background half needed the `color:` presets to move the same way, and is under Changed above.

  The `@apply shadow-md` that had been sitting in `navbar/index.css` went with it. It lost the same way and had never rendered at all: the effective shadow was always the element's `shadow-sm`.

- **Classes passed to `Navbar` land on the `<nav>` once.** `navbar_classes` named `@options[:class]` and then handed its result to `prepend_class_name`, which appends the caller's classes a second time — measured on the AppLayout preview, the four it passes came out twice over.


- **The time picker shows one pair of arrows per column, not two.** Hovering the minutes field drew a second, larger, darker pair with a grey track of its own, sitting on top of flatpickr's — and the native one is the half that is *not* wired to the calendar's value.

  The hour, minute and second fields are `input[type=number]`, and the sheet disarmed their spinners with `appearance: textfield` on `.flatpickr-time input`. Chrome stopped honouring that declaration for number inputs, so it paints its own spinner over whichever field has the pointer regardless. The pair that actually removes it — `::-webkit-outer-spin-button` and `::-webkit-inner-spin-button` set to `appearance: none` — has been in the same file all along for the header's year field; the time row never got it.

  Worth knowing before writing a test for this: `getComputedStyle(input, '::-webkit-inner-spin-button').appearance` does not answer the question. It reports the input's own value — measured, it still says `textfield` with the rule applied and the native arrows gone. The Cypress cover reads the CSSOM instead, which checks what can be checked without eyes: that the declaration reaches the browser through the build and that nothing later reverts it.

- **A `BlockEditor` comment is written across the card instead of one letter per line, and the bubble it is written in has a width.** Two defects in the same feature, both visible the moment you type a comment on `/lookbook/preview/bali/block_editor/with_comments`.

  Every comment body is its own nested BlockNote instance, and it emits a **second** `.bn-container` — `.bn-container.bn-comment-editor` — inside `.bn-thread`. The two rules that lay the editor out beside its threads sidebar, `.bn-with-comments .bn-container` and `.bn-with-comments .bn-container > .bn-editor`, reached those nested containers as well: each became a flex row whose editor child took `flex: 1; min-width: 0`, which is a `flex-basis: 0%` item inside a shrink-to-fit box and resolves to zero. Measured with a comment open: the comment editor 163px wide, its `.bn-editor` **0px**. So the text — and the "Add comment" placeholder with it — wrapped at every character, in the floating popover and in the sidebar alike. Both rules, and the `@media` rule that flips them to a column, now use the child combinator, so they describe the top-level container and nothing else. The rules are from the original comments work (#482); this is not a regression of #832.

  With the text laid out again, the popover had no width of its own: **165px** for a three-letter draft and **966px** for one long line, breathing with every keystroke. The rule meant to bound it keyed off `.bn-floating-composer` and `.bn-floating-thread`, and neither is in the DOM any more — measured 0 elements with a composer open — so its `max-width: 20rem` had never applied. BlockNote floats the card with Floating UI, and the portal it renders into is a hook that does exist; the card is `20rem` wide there now, `max-width: calc(100vw - 2rem)`, and carries its own card edges, since `.document-editor-panel .bn-thread` deliberately strips them for the side panel's list rows.

### Added

- **`label: false` on a filter attribute means "no caption" in the `SimpleFilters` row.** There was no way to ask for one without: `simple_filters_config` derived the label with a `||`, and `nil` and `false` are both falsy, so both fell through to the derivation. The template already knew not to paint an empty one — what could not reach it was a label.

  It matters because the derived one is often worse than none: it humanises the **Ransack** attribute name, not the field's, so `filter_attribute :roles_name` without a label paints "Roles name" — the predicate, humanised, in English — in a Spanish UI, and the I18n fallback does not reach it either, because `roles_name` is a path through an association rather than a column. The advanced popover keeps a label regardless; a row there needs a name.

- **`Bali::Navbar::Component.new(shadow: false)`.** Turns off the drop shadow under the bar, for a layout that already separates it some other way — an app shell whose navbar carries a bottom border continuing the sidebar's draws two dividers otherwise. On by default, so nothing changes for anyone who does not ask. The `default` preview takes it as a toggle.

### Changed

- **Taking a `DeleteLink`'s `<form>` out of the box tree is asked for with `form_class: "contents"`, not inferred from `plain:`.** The menu-item fix that landed earlier gated it on that keyword, on the premise that it means "this DeleteLink is a menu item". It does not: `plain:` is what the API says it is — a button without the `.btn` box — and it travels far outside menus. The same Dropdown builder hands it to `Link` too, `Breadcrumb::Item` passes it with no menu in sight, and in one host alone twelve hand-written `DeleteLink` carry it in the action rows of show pages, none of them from a menu. Gated there, `plain:` grew a second, undocumented meaning that a caller asking for the documented one never signed up for. `Dropdown` now asks for it explicitly, which is the one place that needs it.

  The `inline-block` default moved off the element and into `@layer components` as `.bali-delete-link-form`, and that part is not cosmetic: as two utilities they tied on layer and specificity, so the compiled sheet broke the tie — and it broke it the wrong way. `.contents` is emitted **before** `.inline-block`, so `class="inline-block contents"` rendered as `inline-block` and a `form_class: "contents"` from a call site did nothing at all, silently. From the components layer any display utility passed in wins outright.


- **The `DataTable` toolbar reserves the space for what can collapse instead of showing it and taking it away.** On first load the row used to show every control and then, a full second later, drop four of them into the `⋯` at once. Measured on `/admin/studios`: 5 controls in the row and 0 in the menu at 195ms, 1 and 4 at 1208ms.

  The cause is not that the row grows. It is that the toolbar the server sends is, by definition, the row *before* anything collapses, and nothing can collapse it until the controller exists: the page paints at 260ms and `connect()` does not run until 1189ms, which is how long a 4.8 MB bundle takes to finish executing. Collapsible controls now arrive with their box reserved and nothing drawn in it, and the controller reveals them at the end of its first `apply()`. `visibility: hidden` rather than `display: none`, so the measurement that decides the collapse still measures exactly what it did before. Without JavaScript a `<noscript>` rule reveals them, because the attribute has to come from the server — the flicker it prevents happens before any script runs — and so cannot depend on a script to go away.

- **`Navbar`'s `color:` presets emit Bali classes instead of Tailwind utilities**, so a transparent navbar is finally transparent. `.navbar.is-transparent { @apply bg-transparent }` lives in `@layer components` and the preset put `bg-base-100` on the element as a utility, from a layer that outranks it: measured on `/lookbook/preview/bali/navbar/with_sidebar_burger?transparency=true`, the background stayed `oklch(1 0 0)` with `is-transparent` on. `Navbar::Component::COLORS` now maps to `navbar-base`, `navbar-primary` and the rest, and `navbar/index.css` declares them above the state rule — same layer, same specificity, so source order decides.

  Two consequences worth knowing. A host that reads `COLORS`, or that has CSS matching `.navbar.bg-primary`, sees different classes on the element. And a host that wants to override the preset with a utility of its own now wins outright, instead of tying against `bg-base-100` and depending on the order of the compiled sheet.

- **The "Navbar + Sidebar + Content" preview is one band of chrome, and says each destination once.** It is the reference app shell a host copies, and it read as three stacked white bands with the navigation printed twice.

  The navbar carried `Dashboard`, `Movies` and `Studios` as `start_item`s while the `SideMenu` beside it carried the same three. In this configuration the sidebar owns navigation and the navbar is the account bar, so those are gone. The command palette moves from the far right — wedged between the bell and the avatar — to the first position on the left, where a search field belongs, and its trigger is `style: :soft` instead of `:outline`: daisyUI mixes 8% of `base-content` into `base-100` for it, which reads as a filled well rather than a bordered button, with no loose utility to do it. The navbar also asks for `shadow: false` now, because its bottom border is already the divider.

  The breadcrumb comes out of `Bali::Topbar` — a 56px row with its own `bg-base-100` and bottom border, whose only content was the trail — and renders above the page title on the page's own background. Dropping the `with_topbar` slot is what turns AppLayout's default mobile row back on (`fixed_sidebar? && !topbar?`), so the `lg:hidden` hamburger still opens the sidebar on a phone.

### Documentation

- **The migration guide's deprecation recipe no longer reports a false clean, and says what a Ruby suite cannot see.** Five additions, all from migrating a 235-file application against `beta.1` and `beta.2`.

  The important one: grepping the suite output finds only the deprecations emitted **per render**. One emitted in the body of a class — `FilterForm.simple_filter` is the live example — fires once per process when the class loads, so it does not repeat if the class was already loaded, never happens at all if the batch does not load that class, and makes a later run over a subset *look* clean. Measured: one lane came back with no warnings and a fresh runner printed them. The guide now gives `RAILS_ENV=test bin/rails runner 'Rails.application.eager_load!; warn "EAGER LOAD OK"'` as the authoritative sweep for that family, with the two details that make it work — it has to be the test environment, because eager loading is off in development and the clean means nothing, and it needs a sentinel, because a runner that dies half way prints a short list that reads like a clean bill of health. Both inventories are needed; neither is a superset of the other.

  Also: a **gem** from the group can render the package too (`bali-auth` does), it needs its own compatible release, and the host's suite cannot see it — ~4970 tests passed with three screens of a mounted engine answering 500. A new "what the suite cannot see at all" section, since fifteen of `beta.2`'s sixteen commits were CSS and JavaScript and the host suite did not move a digit. The two entries under "Behaviour changes with no API change" that actually **raise** are now marked as such, because a reader scanning for "what breaks" skips a section whose title says nothing does. And the search placeholder note now says the half that decides it: `human_attribute_name` only returns your language if the model's attributes are translated, and it cannot reach a Ransack path through an association at all.

- **The migration guide no longer sends you to define `--bali-z-hovercard`, a token nothing declares.** The hovercard shares the tooltip tier — the guide's own table said so thirty lines above, and `HoverCard::Component` documents it too; only the prose disagreed. It fails in the worst direction: a host that declares the invented token sees no error, no warning, and not even the `9999` fallback, which `zIndexFor` reaches only when Bali's stylesheet is missing from the page. The override just reads as a no-op. A test now fails the build if the guide ever names a tier the scale does not declare.

## [v3.0.0.beta.2] - 2026-08-03

### Fixed

- **A pinned sidebar no longer paints over the navbar and the banner above it.** `AppLayout` offset only `.app-layout-content` for a fixed sidebar, but `.app-layout-banner` and `.app-layout-navbar` are full-width siblings *above* the main area, and `.side-menu-component--fixed` is `position: fixed; top: 0; height: 100%`. So the sidebar covered their left `--bali-side-menu-width`: on `/lookbook/preview/bali/app_layout/with_navbar` the navbar's brand was invisible and its first link rendered as "hboard", and with the impersonation banner on, its icon and half its text went under the sidebar too. Both now take the same offset, from the same variable and with the same collapsed variant, as the content. `<body>` had been carrying `app-layout--has-navbar` since the slot existed, with no rule reading it.

- **The "Navbar + Sidebar + Content" preview shows the composition a host should copy.** Three things were the preview's own markup, not the components'. The breadcrumb was dropped bare into the `topbar` slot, where it measured 20px tall with zero padding on every side — `.breadcrumbs { padding-block: 0 }` is deliberate and the slot adds none, so the chrome has to come from `Bali::Topbar`, which is what the dummy's `/admin` bar uses: 56px from the shared `--bali-chrome-height`, `px-4 md:px-6`, a bottom border, and the `lg:hidden` hamburger that opens the sidebar on mobile. Its items passed no `icon:`, which `Breadcrumb::Item` has always accepted. And the navbar's end item was a naked 32px `Avatar` — it is now the same `Dropdown` + `Avatar` + name + `chevron-down` the dummy renders, next to the search-with-shortcut, notifications and help controls it has.

  The navbar itself measured 65px against the sidebar's 56px, so the two dividers were 9px apart: daisyUI sets `.navbar { min-height: 4rem }` and its `.menu { padding: .5rem }` stacks another 16px inside the navbar's own 16px. The preview now asks for `min-h-0 bali-chrome-height`, which is the general way to put a navbar on the app-shell chrome line, and `fullscreen: true`, whose `px-4` over the navbar's 8px lands the first item on the same 24px gutter as the topbar's `md:px-6`.

- **The `BlockEditor` comments sidebar no longer scrolls sideways.** A thread card in the inline sidebar was 62px wider than the sidebar itself — measured, sidebar `clientWidth` 288 against `scrollWidth` 350 — so the card's left edge was clipped and a horizontal scrollbar appeared inside the panel. The sidebar declares `overflow-y: auto`, which makes `overflow-x` compute to `auto` as well, so the overflow got a scrollbar instead of just spilling.

  It was not the classic flex `min-width: auto` refusing to shrink, and not a missing `overflow-wrap` — the comment body already breaks a long unbroken URL mid-token. BlockNote's own stylesheet sets a hard floor on the card it renders: `.bn-mantine .bn-thread { min-width: 350px }`. Bali skins that card in `.block-editor-component .bn-thread` and never cancelled the floor, so a 288px sidebar was being asked to hold a 350px child.

  The inline rule now sets `min-width: 0`. Both rules are unlayered and both are (0,2,0), so it wins on source order alone — `block_editor/index.css` is imported after BlockNote's CSS in `BlockNoteEditorWrapper.jsx` — with no `!important` and no specificity bump. The portaled `DocumentEditor` panel was never affected: `.document-editor-panel .bn-thread` has carried the same declaration all along, and its `w-80` panel measures 319/319 with the comments open.

- **The Delete item in a menu is the same box as the items beside it.** In `Bali::ActionsDropdown` the destructive item was 12px taller than its neighbours and its clickable area 24px narrower — measured 192x49 with the button inset to 168x37, against Edit's 192x37 — and it lit up two nested hover boxes, one with a 4px radius and one with an 8px radius inside it. In the `DataTable` saved-views dropdown the same defect painted the trash's hover box at 46x36 next to the pencil's 22x24, in the same row.

  One cause for both. Rails' `button_to` wraps its button in a `<form>`, and daisyUI 5 paints a menu item with `.menu :where(li:not(.menu-title) > :not(ul,menu,details,.menu-title,.btn))` — the direct child of the `<li>`. That child was the form, so the form took the padding, the radius and the `:hover`, while the thing you actually click sat inside it with a box of its own: `.menu-item`'s in the dropdown, `.btn btn-xs`'s in the saved views. Note the `:not(.btn)` in that selector — it is why the pencil beside the trash was never affected and the trash always was.

  The wrapper is now `display: contents` in the two places where a `button_to` is a menu item, so it generates no box and the button becomes the item: the Delete row measures 192x37 with the button at 0,0, byte-identical to a link item, and the trash's hover box measures 22x24 like the pencil's. `Bali::DeleteLink::Component` does this only under `plain:`, the keyword `Bali::Dropdown::Component` passes to say "this is a menu item", so what `DeleteLink` renders anywhere else is unchanged.

- **The time picker's `:` reads as the separator it is instead of a third arrow glyph.** It is the only thing giving `12 : 00 PM` its structure and it was the least visible element in the row. Two causes, both measured on `/lookbook/preview/bali/form/time/with_value` with the picker open.

  It **inherited** the calendar's `font-size: 0.875rem` while `.flatpickr-time input` sets `1rem` explicitly — 14px against the 16px digits it separates. And it shared a `width: 2%` rule with `.flatpickr-am-pm`, which overrides itself to `18%` in the block below, so the 2% only ever applied to the colon: a **6.12px** box with no room for air. The hour stepper's arrows are `position: absolute; right: 0` on the hour's wrapper, whose right edge *is* the separator's left edge — leaving **0.81px** between the triangle and the glyph, which is why it read as part of the controls.

  It is `width: auto` with `0.5rem` of inline padding and an explicit `1rem` now: the box goes to 20.98px and the glyph sits **8px** clear of the arrow, at the same size and weight as the digits. Nothing else moves — the calendar stays 308px, the time row stays 48px, and the `hasSeconds` variant with two separators still measures `scrollWidth === clientWidth === 306`. `flex: none` is part of it because the number wrappers are `flex: 1`, so without it the separator is the only child that can be squeezed when the row tightens. Colour was never part of the defect: an existing `@apply text-base-content` already gave it the digits' colour.

- **The toolbar separator sits on the row's rhythm instead of carving a hole a third wider than every other gap.** Between the "what the view contains" group and the "how it is remembered" group the toolbar measured **48px border box to border box**, against **16px** for every other pair in the same row. Measured on `/lookbook/preview/bali/data_table/complete`: the row's `column-gap` is 16px, and daisyUI's `.divider-horizontal.divider` adds `width: 1rem` **of its own** on top of it, so the hole was `gap + 16 + gap` with 23px of blank on each side of a 2px rule.

  `mx-0` was doing its half of the job — the margins genuinely compute to `0px`, because `.mx-0` and `.divider` are both specificity (0,1,0) and `.mx-0` comes later. The width is the half no utility can reach: `.divider-horizontal.divider` is (0,2,0) in the same layer, and adding `w-px` to the live element still computed `width: 16px`. So the daisyUI divider had to go rather than be trimmed.

  It is a plain `w-0.5 h-6 bg-base-content/10` now. The rule measures the same 2×24 and paints the same colour — `bg-base-content/10` compiles to the identical `color-mix(in oklab, …)` daisyUI uses for `--divider-color`, so themes behave exactly as before — and the frontier is 34px: 16 + the rule + 16, the same gap as everything else in the row. `DocumentPage`'s actions separator had the same `divider divider-horizontal mx-0 h-6` for the same purpose and got the same treatment. The `mx-1` dividers inside `DocumentEditor`'s formatting toolbar are left alone: that is a different rhythm, deliberately chosen.

- **A navbar whose only burger opens the sidebar stops throwing on every scroll, and four more `?.` guards that were not guards.** `this.fooTarget?.bar` reads as "use the target if it is there" and does the opposite: the getter Stimulus generates for a singular target **throws** when the element is missing, and `?.` is evaluated on the getter's result, so it never gets its turn.

  `NavbarController#updateBackgroundColor` was `this.burgerTarget?.offsetHeight || this.element.offsetHeight`, and the fallback its author wrote was **unreachable**. It matters because `Burger::CONFIGURATIONS[:sidebar]` is empty, `:alt` points at `altBurger`, and the `href:` form never calls `configure_attrs` — so a navbar whose only burger is `nav.with_burger(type: :sidebar)`, the natural composition for a hamburger that opens the `SideMenu`, declares no `burger` target at all. Rendered and measured: that navbar comes out with `allow-transparency-value="true"` and only a `menu` target, so with transparency on every throttled scroll event threw in there and `removeIsTransparent()` never ran — the navbar stayed transparent over the scrolled page for the rest of the session.

  Nothing caught it because the component renders a `type: :main` burger as a **fallback** when the slot is empty, so both existing navbar previews and both dummy layouts have the target and look fine. There is a preview for it now: **Sidebar burger + transparency**, which composes the configuration that was broken and scrolls far enough to prove the background comes back.

  Four more of the same shape are corrected — `Dropdown` and `Filters::MultiSelect` on Escape, `Status` on close — plus a fifth the report did not name: `ModalController` wrote `if (this.wrapperTarget)`, which is the same mistake spelled as a condition, throwing instead of answering false. In the Navbar the `||` stays, because it earns its keep when the target *is* there: the burger is `lg:hidden`, so above the breakpoint its `offsetHeight` is 0 and the navbar's own height is the right thing to measure the scroll against.

  `test/bali/stimulus_target_guards_test.rb` greps every `.js` the package ships for all four spellings of the lie (`?.`, `??`, `if (…)`, `&&`/`||`) and fails the build with the correction for each. A grep rather than a lint rule on purpose: the package lints with StandardJS, which accepts no rule configuration by design, so one custom rule would mean replacing it with a hand-configured ESLint, a second config and a second CI job. It blanks out whole-line comments before scanning — every one of these fixes explains itself by quoting the shape it replaced, and the grep cannot tell the quotation from the crime.

- **The previews stop writing a second `card-body` inside a `Card`, which was doubling the padding of everything a host copies.** `Bali::Card::Component` emits its own `<div class="card-body">` and takes `body_class:` for whatever else the call site wants on it. Twenty-two places wrote a second one inside the Card block anyway, so the content sat inside two. daisyUI declares `.card-body { padding: var(--card-p, 1.5rem) }` and nothing sets `--card-p` at size `md`, so it was a flat 24px twice: measured on `/lookbook/preview/bali/dashboard_page/default`, a 728px card with its content at 630px — **48px a side instead of 24**.

  The sweep covered every preview in the package and every view in the dummy: two `DashboardPage` previews, two `FormPage` previews, two in the `ThemeSampler`, and fifteen dummy views (`landing`, both `settings` pages, the three `direct_uploads` templates). The extra classes the hand-written divs carried — `space-y-4`, `p-4`, `text-center`, `prose`, `py-8` — moved onto `body_class:` rather than being dropped.

  The two `FormPage` previews are the same defect one level removed, since `FormPage` wraps its own body in a Card; they get a plain wrapper div instead. **`FormPage` deliberately does not gain a `body_class:` passthrough**: its Card is conditional (`card?` is `!drawer?`), so in a drawer it renders no `card-body` at all, and a passthrough would silently swallow the caller's classes in exactly that case.

  `test/requests/nested_card_body_test.rb` pins it from both ends — a request test that asserts no `.card-body .card-body` in the affected previews, and a static one that forbids any preview template from writing `card-body` by hand, so a preview added tomorrow is covered without anyone remembering to list it.

- **A `SlimSelect` with `multiple` grows to fit its pills instead of cutting them in half.** With four values chosen in a 260px-wide control the pills wrapped to a second row and the box did not. Measured on `/lookbook/inspect/bali/form/slim_select/multiple`: `.ss-values` had a `scrollHeight` of 56px inside a `.ss-main` stuck at 40px, and because `.ss-main` is `align-items: center` the overflow split both ways — the first row started 9px above the content box and the second ended 47px into a 38px one. **Both** rows were clipped, and the second row's delete buttons were unreachable.

  Two rules made it. `.ss-main` declared `h-10 min-h-[40px]`, a fixed height; and the clipping is daisyUI's, because SlimSelect copies the native select's class list onto `.ss-main`, so the element carries `.select` — which sets `overflow: hidden`. The height is `auto` now with the 40px minimum kept, plus 6px of block padding to reproduce the breathing room the fixed height used to give a single row. The trigger measures 70px with two rows of pills and nothing crosses its padding box.

  **The declaration had to change, not go.** `bali/slim_select.css` is unlayered on purpose; deleting `h-10` would have handed the box straight back to daisyUI's `.select { height: var(--size) }` in `@layer utilities` — 40px again — so the rule says `height: auto` explicitly. daisyUI answers the native case the same way: `.select[multiple] { height: auto }`. Capping the height and scrolling `.ss-values` was the alternative and lost: a click anywhere on `.ss-main` opens the list, so the scroll surface and the widget's own click target would be the same box, and every pill carries a delete button that has to stay reachable.

  Single select, placeholder and disabled are unchanged at 40px, and `.slim-select-sm` — the variant the `Filters` conditions use, and never a multiple — is identical at 32px. `cypress/e2e/slim-select-multiple.cy.js` pins both directions, driving the wrap from `cy.viewport` because the trigger is `w-full` and only a narrow window makes four pills wrap. It reads `offsetTop`/`offsetHeight`, never `getBoundingClientRect`: `.ss-value` carries the `ss-valueIn` animation whose 0% frame is `scale(0.8)`, so a rect measures the transformed box and not the layout box.

- **A drawer trigger that names no drawer stops opening every drawer on the page — one of which nobody then closes, leaving the page alive but deaf to the mouse.** On a page with `AppLayout` and `FeedbackWidget` — the composition the guides recommend — clicking an ordinary "New…" button and submitting the form left the whole document unclickable. Nothing was visible on top of it; the drawer had, to all appearances, closed.

  A `drawer#open` trigger may name the overlay it opens (`data-drawer-id`) and usually does not, because the common page has one shared overlay: `ModalController#open` then dispatches `bali:drawer:open` with no `id`, and `setOptionsAndOpenModal` skipped its id check entirely in that case. So every drawer holding the three targets answered — which was only ever right while a page carried one. The package broke that assumption itself: `Bali::FeedbackWidget` renders its own `Bali::Drawer`, so **one click opened two drawers**. `submit` then closes the panel whose controller handled the click, and only that one; the other stayed `showModal()`-ed. A `<dialog>` in the top layer makes every node outside its subtree inert, and the drawer's own CSS strips the UA box (`inset: auto`, transparent) and hides the overlay once `drawer-open` is off — so the stranded dialog rendered nothing at all while still owning the document.

  Traced through the flow, which is what named the culprit — reading class names or the `open` attribute would have reported a page in perfect health:

  ```
  after load  :: main-drawer[open=false :modal=false]  feedback-widget[open=false :modal=false]
  drawer open :: main-drawer[open=true  :modal=true ]  feedback-widget[open=true  :modal=true ]
  after submit:: main-drawer[open=false :modal=false]  feedback-widget[open=true  :modal=true ]
  ```

  `Bali::Drawer::Component` takes **`shared:`** now. It defaults to `true`, so every existing drawer keeps the markup and the behaviour it had, and the attribute is only written when it is false. `FeedbackWidget`'s panel sets `shared: false`: it is opened by the widget's own button, which has always named it by id, so it never needed the broadcast — and its content is an iframe that a broadcast overwrites. A host with a feature drawer of its own now has the same opt-out.

- **The `SideMenu` module switcher closes on a click outside it and on `Escape`.** It stayed open over the rest of the page: the only thing that shut it was pressing its own trigger again. That is not an oversight in a controller — it is the whole behaviour of the element. The switcher is a native `<details>`, chosen on purpose because the focus-based dropdown pattern is fragile on iOS Safari (focus lost to the slide-in animation, blur on scroll), and `<details>` toggles on its `<summary>` and on nothing else. It stays a `<details>`; the two ways out that every other popup in the package offers are added to it.

  Closing on `pointerdown` rather than on `click` is deliberate: a press that starts inside the open panel and drifts a pixel before release retargets the click to whatever is underneath, and a click-bound handler reads that as "outside" — closing the panel out from under the item the reader was pressing. The press is where the intent is. Pressing the summary itself needs no special case in either direction: while the panel is open the press is inside the `<details>`, and while it is closed there is nothing to close, so the native toggle runs afterwards as the click's default action. `Escape` closes the switcher before the drawer it may sit in — innermost first, the precedence the rest of the package already follows — and hands focus back to the summary rather than dropping it on `<body>`.

  **The controller had to start being attached for this to run at all.** `data-controller="side-menu"` was emitted only for `collapsible:` or `fixed:` sidebars, and a switcher needs neither — an inline sidebar with three modules, which is exactly what the preview composes, had no controller for any of this to live in. A menu with more than one authorized module now asks for the controller on its own account. A single-menu sidebar renders no switcher and is unaffected.
- **A submit button that is waiting keeps being a button.** Clicking **Save** in a modal or a drawer made the button vanish, leaving a spinner floating where it had been, with one letter of the label showing through the spinner as it turned. Both symptoms are the same cause: in daisyUI 5 `.loading` is not a modifier that adds a spinner — **it is the spinner**. It sets `aspect-ratio: 1`, a width of six selector units and `background-color: currentColor` masked by the spinner SVG. Put on the `<button>`, it collapsed the box — measured 66×40 to 34×40 — painted the button itself as the spinner, and left the label inside to show through the holes in the mask.

  The spinner is now a child element and the button keeps `.btn`. Its width is pinned to what it measured before the swap, because the label is what was holding it open: exchanging "Save" for a 20px spinner without pinning resizes the actions row at exactly the moment the user is waiting on it. The height needs nothing — `.btn` sets it. The button is `disabled` with `aria-busy="true"`, and the label is kept hidden inside rather than serialised, so whatever the call site put in the button — an icon, a translated span — comes back intact on the one path that returns: a form that fails `checkValidity()` before the request is even made. `ModalController` owns the code and `DrawerController` inherits it, so both overlays are covered.

  **`Bali::Button::Component`'s `loading:` keyword had the same defect** and no report, since nothing in the package rendered it. `loading: true` emitted `class="btn btn-primary loading loading-spinner"` *and* a correct `<span class="loading loading-spinner loading-sm">` inside — so the button collapsed to a 34px square exactly like the one above, while carrying a perfectly good spinner it had crushed. The class is off the button now. `loading:` also sets `disabled` and `aria-busy`: the old `.loading` disabled the button too, through `pointer-events: none`, but as a side effect of the class that was destroying its box; saying it in the attribute keeps the behaviour and adds what the class never gave — the button stops being submittable and focusable. `disabled: true` alongside `loading: true` is now redundant.
- **The `RichTextEditor` previews say why they are empty instead of looking broken.** `/lookbook/inspect/bali/rich_text_editor/default` answered 200 with an empty body — not even the `<div>` the component's template opens — and so did `readonly`. Nothing was broken: `render?` returns `Bali.rich_text_editor_enabled`, the package ships that flag as `false`, and a ViewComponent whose `render?` is false emits no markup at all. The preview was off on purpose and had no way of saying so, which reads exactly like a component that fails silently.

  Each scenario now checks the flag and renders the reason when it is off: that the flag is the package default, that it exists because this editor is the only reason the package declares roughly thirty-five `@tiptap/*` optional peers plus `lowlight` and `highlight.js`, that the component is deprecated in v3 and removed in v4, and where the replacement is. `ENABLE_RICH_TEXT_EDITOR=1` still boots the dummy with the real editor, and with the flag on the notice disappears and the component renders exactly as before — both directions are pinned by `test/requests/rich_text_editor_preview_test.rb`, along with the link the notice offers, so the migration it recommends cannot rot into a 404.

  The flag check is written into each scenario rather than wrapped around the render, so Lookbook's **Source** panel keeps showing the component call, which is the thing a host copies out of a preview.
- **The icon previews stopped answering `uninitialized constant Bali::Icon::Preview::LucideMapping` for a constant that exists.** `/lookbook/inspect/bali/icon/lucide_mapped_icons` 500'd, and so did the brand, regional, custom-domain and all-existing catalogues — every icon preview that reads a sibling constant. The constant was never missing: from `bin/rails runner`, in a process that had never touched it, `Bali::Icon.constants` lists `:LucideMapping` and `Bali::Icon::Preview.new.lucide_mapped_icons` runs. It failed **only over the request path**.

  `Module.nesting` is captured when a file is parsed, and it stores a reference to the module *object*, not its name. Lookbook loads every `preview.rb` at boot to build its navigation, capturing the `Bali::Icon` that exists at that moment; a later `reload!` has Zeitwerk discard that module and create another, the sibling autoloads into the new one, and the preview class — still held by Lookbook's registry — keeps resolving `LucideMapping` against the old one, where the autoload no longer exists. Writing the name in full (`Bali::Icon::LucideMapping`) resolves it against the `Bali` in effect at call time instead, which is the only spelling that survives a reload.

  The six references in `app/components/bali/icon/preview.rb` are now qualified, and `test/requests/icon_previews_test.rb` covers both halves of why this went unseen. It **requests** the previews over HTTP, because that is the only path where the defect appears and no component test goes near it; and it **forbids the pattern statically** in every `preview.rb` in the package, lexing each file with Ripper so the constant `Item` is told apart from the string `'Item 1'` and the method `with_item`. The sweep found no other file with the same shape, but a preview added tomorrow gets the same guarantee without anyone remembering to add a request for it.
- **Every file field, text area and time zone select stopped answering `SystemStackError` after the first code reload.** In development, a `FormBuilder` field would render fine on a freshly booted server and then 500 on `stack level too deep` from the moment anything triggered a Zeitwerk reload — for the rest of that server's life. The reproduction is two lines: request the preview (200), `touch` any file under `lib/`, request it again (500).

  Three modules keep Rails' own helper under a `rails_*` name so the Bali implementation can live under the canonical one, and all three did it with `alias rails_file_field file_field`. `alias` captures whatever the name resolves to **at that moment**. On the first load the module is not included yet, so it captures ActionView's and everything works. On a reload the file runs again with the module already included in `FormBuilder`, so the alias captured Bali's own override — and `rails_file_field` became a call to itself. The stack said so plainly, alternating between `file_field` and `custom_file_field` until it ran out.

  Each of the three now binds the superclass's method by its owner (`define_method(:rails_file_field, superclass.instance_method(:file_field))`), which cannot mean anything but Rails' regardless of load order or how many times the file is re-executed.

  **The test reloads the three files on purpose**, because that is the one thing the suite never did: it boots cold, which is exactly the state where the bug is invisible. It pins both the cause (each saved name shares Rails' `source_location`, not Bali's) and the symptom (the three fields still render markup instead of recursing).
- **The `DataTable` toolbar's `⋯` valve now reacts to a control that grows *after* the first layout, which is when the controls that grow actually grow.** `toolbar-overflow` recomputed on three signals: mount, a breakpoint crossing, and a change in the row's own width. None of them covers the ordinary case. SlimSelect replaces its `<select>` with a wider widget, flatpickr mounts its own input, a webfont finishes loading — all of them after the controller has already decided the row fits, and none of them changes the row's width, because that width is set by the parent. The row then overflowed with the `⋯` still hidden and nothing to press.

  Two things were wrong and both had to change. The measurement: the early return compared only the width the row *has*, so the width it *needs* could double without anything noticing; it now compares both, and records them after applying rather than before, since collapsing lowers `max-content` and the stale reading guaranteed a second pass. And the observation: the `ResizeObserver` watched only the row, whose border-box does not move when its contents grow — measured, appending a 300px child produced **zero** callbacks. It now watches each toolbar item too, which is what actually changes size when a widget mounts inside one.

  The regression test widens a control by 600px with the viewport untouched, which is the shape of the real case and the one thing `cy.viewport()` cannot express — resizing the viewport exercises the signal the controller already listened to. It fails on the old controller and passes on the new one.

- **The dummy has two reference index pages instead of four, and both live in the layout a host actually ships.** `/movies` and `/admin/movies` were two takes on the same page, and so were `/studios` and `/admin/studios` — four pages teaching between two and four conventions for the same job, with the richer half of the work split across the pair. `/studios` had the complete `FilterForm` (`storage_id`, `group_by_attributes`, saved views, `context:`, `persist_enabled`), the shared `_listing` partial and the drawer's stream; `/admin/studios` had the sidebar chrome, the guards for a record with no country or status, and nothing else. Neither page was the reference on its own.

  The `/admin` layout is the canonical one — it is the default and the common shape — so the work moved **into** it rather than being rebuilt: the full `FilterForm`, the six toolbar surfaces, `_listing`, the drawer's `create.turbo_stream.erb` and the `submit_group` form are the ones that were already verified, repointed at the admin routes. The non-admin indexes are gone, `resources :movies` lost its `index`, `resources :studios` is gone entirely, and everything that linked to them (navbar, dashboard, landing, the sidemenu example, the movie form and detail pages, `Movies::BulkActionsController`) points at `/admin`. Clicking **Movies** in the navbar now lands in the admin layout, which is the visible change and the intended one.

  Two things fell out of the move. The listing's `studio.status.humanize` had no guard while the `size&.humanize` beside it did — and `Studio` only validates `name`, so the page's own drawer could create a record that put its index in a 500 (#834); the admin listing's guards came along and now render an em dash, which is the data. And the three request tests that only ever asserted `/movies` answered 200 went with the page they tested, while the component tests that used `/movies` and `/studios` as a stand-in request path now name a route that exists.
- **A listing filtered down to nothing stops blaming the data, and a view saved from a simplified index keeps its cut.** Two reports, one cause: the simple filters and the quick search were never part of the `FilterForm`'s idea of its own state. `active_filters` was built from `query_params`, which is built from the attributes declared with the `filter_attribute` DSL — and a plain `Bali::FilterForm.new(scope, params, simple_filters: [...])` declares none, so `attribute_names` is `["s"]` and the answer was `{}` however many filters the user had chosen.

  **What that broke first.** `Table` picks its empty state from `active_filters?`. With it stuck at `false`, a filter or a search that cut the result to zero produced "No records yet" and an invitation to create one — the listing telling the user there was no data when what there was, was a filter. `active_filters_count` sat at zero next to it. Both now read the three surfaces that can narrow a listing: the declared attributes, the simple filters, and the quick search. The quick search counts as a filter, because it cuts the result exactly like one; Ransack's `s` (sort) still does not, because sorting is not narrowing.

  **What it broke second.** `current_view_payload` carried `attributes`, `groupings`, `combinator`, `search_value` and `group_by` — and a simple filter's value is in none of them. It never becomes an ActiveModel attribute: it lives in `q_params` and goes straight to Ransack. So a saved view created from a simplified index was born without the thing that made it worth saving. Measured on the dummy: `country_eq=USA` cutting 25 rows to 5, and the payload coming out `{"attributes"=>{}, "search_value"=>"pic", "group_by"=>"size"}`. The payload has a `simple_filters` key now, applying a view restores those values, and — same contract that already governed `attributes` — a view **replaces** the state rather than merging into it, so a payload saved before the key existed clears them, which is the state that view actually describes.

  The shape of the fix is one method, `active_simple_filters`, which is now the single place that knows how a simple filter definition turns into a key/value pair. `simple_filters_active?`, the Ransack params builder and the saved-view payload all read it, so they cannot drift again; the Ransack builder is the only caller that asks for date ranges to be left out, because those are applied with a `where` clause rather than a predicate.

- **A comment from someone outside `comments.users` stops taking the whole editor down with it.** `DocumentEditor` and `BlockEditor` painted an empty content area and an empty table of contents, with `Uncaught Error: User 1 resolved thread 1, but their data could not be found.` in the console. Nothing in that message says "the document is gone", and that is what happened: BlockNote reads a resolved thread's user **synchronously** while rendering it and throws when the id is not in the user store yet; the throw escapes into React's render, and the error boundary above the editor blanks everything below it — document, TOC and sidebar alike.

  Every path that fills that store is asynchronous. `resolveUsers` returns a promise, and `RESTThreadStore` polls for new threads on top of it, so a thread whose author or resolver is not in the static `users:` list loses that race. That is not an exotic case: it is anyone who has left the organisation, and it is the *normal* case for a host that resolves people through `comments.users_url` instead of enumerating them up front. The pre-population that used to guard this only ever wrote the static list, so by construction it could not cover an id it had never been told about.

  The fix moved to the thread list, where the ids actually appear. Every time the threads change, the real load starts for the ids they reference and a placeholder is written for whatever is still unknown. `loadUsers()` registers those ids as in flight before it awaits, so the placeholder does not cancel the fetch — it only guarantees the synchronous read finds something, and the resolved name replaces it when it lands. The name shown meanwhile is `bali_view.block_editor.user_fallback`, already translated, so an unknown author degrades to "User 42" instead of a white screen. The subscription is registered on the line after the thread store is constructed, before any reference to it escapes, which is what puts it ahead of BlockNote's own subscriber.

  **Not version-specific, and neither is the fix.** Reproduced identically on `@blocknote` 0.46 and on 0.52.1, the version this package declares as its peer floor. Worth saying because the two fill the store differently — 0.46 exposes a `userCache` Map and reads through `getUser`, 0.52 exposes `setUser` and reads its backing store directly — so a guard written against either internal shape is a silent no-op on the other. Writing goes through whichever of the two is present; reading is `getUser`, which both keep.

  In the dummy, `BlockEditorAuthentication#current_user_id` fell back to `'1'` while every view declared `user-1`, so every comment the dummy persisted was authored by a stranger to its own UI. That is what surfaced the bug, and the default now matches `DocumentsController::DEMO_USERS`.

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

- **A tooltip that is moved in the DOM keeps working; before, it died silently the first time its element reconnected.** `TooltipController#connect` handed tippy `this.contentTarget.content`, the `<template>`'s own `DocumentFragment`. tippy **moves** what it is given rather than copying it — `setContent` runs `appendChild` on anything that is an `Element` or a `Fragment` (`tippy.esm.js:491`) — so the `<template>` was emptied by the first connect and stayed empty for the life of the page. Nothing noticed while the element stayed where it was rendered. But when the same DOM node is disconnected and reconnected, `connect` re-read a `<template>` with nothing in it, the empty guard returned, and neither the balloon nor the tab stop was rebuilt. Measured in Chrome on `bali/tooltip/help_tip`, removing the element and re-inserting it: at page load `template.content.children` **0**, tippy built **true**, `tabindex` **"0"**; after re-inserting, children **0**, tippy built **false**, `tabindex` **null**. The first row is the defect on its own — the template is already empty the moment the first connect returns.

  **This is older than #776, #788 and #796 and is not a regression from any of them**; it has been there since the component passed a `<template>` to tippy. What reaches it is anything that relocates the element instead of replacing it with fresh markup: a list reordered so that siblings are moved rather than re-rendered, a node pulled out of the DOM and put back, a morph that keeps the tooltip's element and reconnects its controllers. A Turbo Stream that replaces the HTML does **not** land here, because it arrives as new markup with its `<template>` full. Measured on Stimulus itself, reversing a row of three controllers reports 3 disconnects and 3 connects even though every move happens in one tick, so an ordinary synchronous reorder is enough.

  The fix is one line — tippy is handed `this.contentTarget.content.cloneNode(true)` — and the reason it is a clone rather than the `innerHTML` string `HoverCard` uses was measured rather than assumed. Over two connects of the same node: moving leaves the template empty, gives an empty balloon on the second connect, and connects a nested `data-controller` **1 of 2** times; `cloneNode(true)` and `template.innerHTML` both leave the template intact, both rebuild the balloon in full, and both connect the nested controller **2 of 2**. Neither copy duplicates an `id`: a `<template>`'s content is inert and outside the document, so the balloon's copy is the only one `getElementById` can reach — measured 1, never 2. The two produced byte-identical markup on both shapes the package ships, SVG namespace included. `cloneNode` won on the tiebreak: the string route is tippy's *other* branch, the one guarded by `allowHTML`, and with that flag off it sets `textContent`, so a markup-only balloon — the `<svg>` and `<img>` shapes #788 had just made explicitly supported — would render as escaped text. Cloning stays on the branch this component already used, and `direct_upload` and `document_editor` read their templates the same way.

  **What a host that updates will notice.** The `<template>` is no longer drained, so anything reading it after connect now finds the content the server rendered instead of an empty node. The one thing a copy cannot carry is an event listener attached to a node *while it was still inside the `<template>`* — measured, it does not fire. That trade is the right way round here: template content is inert markup the document never held, so there was no live node for a caller to hold a reference to. `Dropdown` is the opposite case and deliberately keeps the opposite symmetry — its menu **is** rendered DOM the reader operates, complete with ids, Stimulus targets and listeners, so it moves the real node and `disconnect` puts it back where the server rendered it. Restoring on exit was considered here and rejected: it would leave the template empty for the whole life of the connection anyway, and reaching into tippy's popper to retrieve the nodes would break the moment a caller called `setContent`.

  `cypress/e2e/tooltip-controller.cy.js` grows three cases: the template is still populated after connecting, the balloon is rebuilt after the element is removed and re-inserted, and every balloon is rebuilt after the four tooltips of `all_placements` are reordered. All three fail against the old code. The reorder case needs care to be honest — asserting immediately after the move reads the instances the *first* connect built and passes against the broken code too, so it waits until every trigger carries a tippy instance whose id did not exist before the move. Verified in the browser that the balloon still joins a modal `<dialog>` through #796's `topLayerHost` path, both before and after a reconnect. **`HoverCard` does not share this defect** and is deliberately untouched: it reads `templateTarget.innerHTML`, a string copy, so its template survives — confirmed in the browser, template intact and tippy rebuilt after the same remove-and-re-insert.
- **`DashboardPage` and `DataTable::SimpleFilters` stop emitting deprecation warnings on the host's behalf.** Both reached for a deprecated API from inside their own templates, so the warning that came out named a call the host never wrote and had no way to change. `DashboardPage` handed `Bali::StatCard::Component` the `icon_name:` that component deprecates — one warning per stat, so the ordinary four-stat dashboard warned four times on every render — and `DataTable::SimpleFilters` built its slim-select filter with the two positional option hashes #785 retired, one warning per such filter on every index page carrying one. **Neither is a behaviour change:** `icon_name:` and `icon:` feed the same attribute, and the positional `(options, html)` pair maps onto `**options` plus `html:` one-for-one, so what both components render is what they rendered before. This is the same leak `PageHeader` already silences for `Level`, and each component now carries a test that pins the silence — asserting the stat card's icon, and the filter's id and classes, right beside it, because the cheap way to quiet either warning is to delete the argument, which deletes what it was for and still passes a test that only counts warnings.

  **Why this is worth a note at all:** a deprecator that warns about nothing gets read as nothing. Rendering the demo app's own 53 pages fired **27** warnings, **14** of them out of these two templates — noise no host can act on, burying the 13 that do name a call site someone owns. That sweep is pinned at zero now, which is what keeps it there: the count is a test rather than a measurement someone has to remember to repeat.

  Nothing else in the package changes. The rest of the work is in the demo app and does not ship: nine of its call sites moved off the positional hashes, and `test/requests/dummy_pages_smoke_test.rb` now reads the deprecator during the sweep it already ran and fails if any page warns. The sweep carries **no exceptions at all**: the four it briefly tolerated were the dashboard and revenue pages demonstrating `Level` and `InfoLevel`, and #808 replaced all four. The guard that fails on an exception which stops firing is what turned that into a deletion instead of a leftover.

- **`Bali::Table::Header` never accepted `align:`, and four call sites passed it anyway.** It is not in the component's signature (`table/header/component.rb:13`), so it fell through `**options` into `hyphenize_keys` and came out as `<th align="right">` — the HTML attribute that has been obsolete since HTML5, honoured inconsistently and impossible to theme. The supported form is `class: 'text-right'`, which the same view already used one line away for `text-center`. Same family as #787: a call site passing a keyword the component does not declare, appearing to work until it doesn't. One component over, `app/components/bali/data_table/previews/with_simple_filters.html.erb` had the identical shape — `variant: :outline` on `Bali::Tag`, which declares `style:` — so the tag rendered with no outline and emitted `variant="outline"` into the DOM. That preview is packaged; the four `align:` call sites are demo app and do not ship.

- **The demo app's two reference listings stopped teaching two different conventions for the same thing.** `/admin/movies` and `/studios` exist to show the same standard listing with the only difference being the filter surface — the advanced `with_filters_panel` on one, `with_simple_filters` on the other. **Both now exercise all six of the DataTable's surfaces**: filters, grouping, saved views, sorting, the column selector and export. `/studios` had only three of them, so half the toolbar the major built was demonstrated in exactly one place and a host reading the simpler page would not have known the rest existed. It now declares `group_by_attributes` (grouping by status, country or size, with the global per-group totals `group_counts` provides), `with_saved_views` against the engine's own store, and a `with_column_selector` whose indices start at 0 rather than 1 — that table is not `selectable:`, so there is no checkbox column ahead of the data.

  Thirteen other things had drifted apart: a subtitle on one and not the other, a `size: :sm` on one primary button (which reintroduces exactly the height mismatch the `⋯` button dropped `btn-sm` to fix — see `page_components/shared.rb:174`), `with_export` on one, a quick-search placeholder on one, `storage_id`/`context`/`persist_enabled` on one, four of six sortable columns on the other, a delete action that asked for confirmation on one and deleted on the first click on the other, and `t` used as a `Table` block variable — shadowing the i18n helper, surviving only because every call inside carried parentheses. Both now declare the same surface, and `with_new_record_link` replaces the hand-rolled `Alert` that bypassed the component's own empty state. The demo app's Spanish locale grew the `studios:` block it never had, so the page is no longer half-translated in one of its two languages.

  **Exercising those surfaces is how #817 and #823 were found**, which is the argument for a demo page that uses all of them rather than describing them. Dropping the `Alert` override exposed `Bali::Table`'s two-branch empty state, whose branch is chosen by `FilterForm#active_filters?` — always `false` for a `Bali::FilterForm.new(...)` that was never subclassed, so a listing the user filtered down to nothing says "No Records" and offers to create one (**#817**). And saving a view from a simplified-filter listing silently drops the filters: `current_view_payload` carries `groupings`, `search_value` and `group_by`, and the simple filters are in none of them, so the view saves, reports success, and comes back with more rows than the user was looking at (**#823**). Both are filed on their own rather than folded in here — #817 also drives the toolbar's active-filter count, and #823 is a different method with the same root, that the simple-filter surface is not represented in the form's state.
- **Three controls in the simplified filter bar sat on their own baseline, and the numeric range had no border until you focused it.** All three are one-line template defects in `data_table/simple_filters/component.html.erb`, and each is the odd one out among six otherwise identical filters.

  The **slim-select's icon** was the only one passing a bare `Bali::Icon` to `addon_left:` instead of going through `icon_addon`, the helper the other five use. The addon lands verbatim inside a `join`, whose `align-items: stretch` cannot stretch a 16px `<span>`, so that icon floated at half height while every other filter's icon filled its control. The **boolean toggle** was the only filter with no caption above it, and the row aligns on `items-end`, so with no height of its own it came to rest on the neighbours' label line rather than on their control line; it now carries `h-8`, the height of a `-sm` control. And the **numeric range** put `join-item` on the flex container wrapping its two inputs rather than on a control — daisyUI uses that class to trim the borders of the element it joins, so applied to a layout div it stripped the border off both inputs, which then looked borderless until focus drew the outline. It moves onto the Min input, the same shape the quick search already used.

  Measured on `/studios` after the change: the eight children of the filter row share a single bottom edge (`bottomsDistintos: [223]`), and the Min input computes `border: 1px` in the theme's border colour.
- **A select could show one value and submit another: two SlimSelect instances were fighting over the same `<select>`.** Reported against the filters panel — pick `Status is Draft`, apply, then change the value to `Done`, and the listing came back with the Draft rows. The widget said `Done`; the `<select>` that `FormData` serializes was empty, so the panel correctly judged the condition unfilled and left it out of the request, and the warning #798 added said so. Everything downstream was right; the value never arrived.

  `SlimSelectController#connect` is `async`, and the `await import('slim-select')` in it is a window in which Stimulus can disconnect the controller — any DOM move does that, and the DataTable toolbar re-parents its items on every overflow recalculation. A `disconnect()` landing in that window runs `teardown()`, which destroys `this.select` while it is still `null` and therefore destroys nothing; the in-flight `connect()` then finishes and builds an instance nobody owns. SlimSelect ships a guard for exactly this — `this.selectEl.dataset.ssid && this.destroy()` — but it is dead code in 3.4.3: `ssid` appears once in the whole bundle, at that read, and is never written. So both instances stayed alive with a `MutationObserver` each on the same `<select>`, and the orphan reverted what the live one wrote. `connect()` and `disconnect()` now carry a generation counter, and an instance that finishes building for a generation that has passed destroys itself.

  **Any host is affected, not just the filters panel**: this is the shared `slim-select` controller, so a `slim_select_group` in a form inside a drawer, or any select that gets re-parented, could drop a value the same way. It is timing, so it shows up as "sometimes": reaching the same widget by a path that rebuilds it leaves one instance and works.

  **Covered by `cypress/e2e/filters-controller.cy.js`**, which re-parents the value container twice in a row — what the toolbar does, and what opens the window. Against the unfixed controller it fails on `Too many elements found. Found '2', expected '1'`. The user-facing case (changing your mind about a value) is in the same file for the behaviour, but it is explicitly *not* a guard: it passes either way, because by the time the panel is reachable the dynamic import is cached and the `await` resolves in the same microtask. That is also why the defect was so hard to pin down from the symptom.

- **Every tooltip in the editor drew its card twice, and the comment composer's Save button carried an empty pill above it.** Two defects with one cause. BlockNote renders every tooltip as `<Tooltip label={<Stack className="bn-tooltip">}>` — the label is the card, and its own stylesheet deliberately zeroes the Mantine box around it (`.bn-mantine .mantine-Tooltip-tooltip { background: transparent; border: none; border-radius: 0; box-shadow: none; padding: 0 }`). This package overrode that reset with a full card of its own, so the two boxes stacked: measured on the `Bold ⌘+B` balloon, the wrapper and the label both computed `1px solid oklch(0.21 0.006 285.885 / 0.12)`, `oklch(0.98 0 0)` and `0 2px 8px`, one nested inside the other. The card now lives on `.bn-tooltip` only, which is where BlockNote put it and where our daisyUI re-skin belongs; the wrapper keeps `z-index: var(--bali-z-tooltip)` and nothing else.

  **The empty pill was the same bug seen from the other side.** The Save button already reads "Save", so a rule hid its redundant tooltip — but it hid `.bn-tooltip`, the contents, and the wrapper it left behind still had a background, a border, a shadow and `4px 8px` of padding. Measured while hovering Save: an 18×10 box painting nothing but itself. With the wrapper back to painting nothing, hiding the label leaves a zero-height box, and the rule needed no other change.

  This is not fallout from `<dialog>` and the top layer — `git blame` dates both rules to #509, in March. Four overlapping blocks collapse into one: the scoped and unscoped copies of the `.bn-tooltip` card were identical, and so were the two `… p` rules. The comments that justified the duplication claimed Mantine portals its tooltips to `<body>`; it does not here, both call sites in `@blocknote/mantine` pass `withinPortal: false`. The one unscoped block is kept anyway, and now says why: a portaled tooltip would escape `.block-editor-component` / `.document-editor-panel` and come out unstyled.

  **Covered by two cases in `cypress/e2e/document-editor.cy.js`.** Mantine mounts a tooltip only while the pointer is genuinely over its trigger, and neither `mouseover`/`pointerenter` nor `focus()` opens one, so the tests drive the cascade rather than the interaction: they mount the markup BlockNote emits inside the real `.bn-container.bn-mantine` and read back what the shipped stylesheets paint — the label draws the card, the Mantine box draws nothing, and hiding the label leaves a box of zero height. Against the code before this change both fail, the second one on `expected 10 to equal 0` — the pill's exact height.

- **The demo app's drawer form navigated away instead of closing, and the two reference forms drifted the same way the listings had.** `/studios` opens its form in a drawer, and saving took the whole page with it — a redirect cannot close a panel. All three pieces of the contract `docs/guides/components.md` documents were missing at once: no `respond_to` on the controller, so the response was always a redirect; no `data: { turbo: true }` on the form, so a `text/vnd.turbo-stream.html` would not have been applied even if one arrived; and no `drawer#submit` on the submit button, so `ModalController#submit` never ran. `f.submit_group(..., drawer: page.drawer?)` supplies the last two on its own — that is what the helper is for — and the controller now answers `turbo_stream` by replacing the listing node, the same shape `/admin/movies` already used for its own stream. Measured end to end: the drawer closes, the row appears in place, the count goes 25 → 26, and the URL never changes.

  The rest is the forms half of the same drift: `/studios` gained the subtitle and breadcrumbs it had keys for but never rendered (both of which `FormPage` drops by itself inside a drawer, so they cost the drawer nothing), and its three hardcoded English strings moved to the locale files. `/admin/movies` gained the `error_summary` it was missing — in a four-section form a 422 that only marks fields leaves the first screen looking fine — and its two hand-mounted widgets moved onto the `FormBuilder`: `f.block_editor_group` and `f.direct_upload_group`, which bring the `<legend>` and the field errors that a bare `<label class="label">` did not. Those two helpers had no call site anywhere in the repo until now.

  **Deliberately left different.** `/admin/movies` keeps `card: false` and its four section `Card`s. It looks like it rebuilds what `FormPage` already does, but it is a four-section catalogue with a `Stepper`: collapsing it into the component's single Card would delete the section boundaries with nothing to replace them. `/studios` is the short form and uses the default. Two lengths, two legitimate shapes — what was missing was saying so in the code.

- **The published recipe for replacing a listing over Turbo Streams was only correct from half the places hosts use it.** `docs/guides/components.md` and the v2→v3 migration guide both show `turbo_stream.replace Bali::DataTable::ListingIdentity.for(@filter_form)` re-rendering the shared listing partial. That is right from `index`, whose request carries the grouping, the filters and the sort. It is wrong from a form inside a `Modal` or `Drawer`, and the guides did not say so: the overlay posts to the **form's** action with `fetch` and adds only `layout=false`, so `request.query_parameters` is `{"layout" => "false"}` and nothing else. The listing comes back ungrouped and unfiltered — and worse, that single param is what the toolbar's links and every ransack `sort_link` are built from on the way out, so the page keeps answering 200 while quietly losing the state on the next click.

  Measured on the dummy's `/studios?group_by=country`, creating a studio from the drawer: before, the listing returned with **0 group headers** and a flat 10 rows, **12** links carrying `layout=false`, and **0 of 5** `sort_link`s still carrying `group_by`. After, 6 group headers, 0 contaminated links, 5 of 5 sort links intact.

  Both guides now carry the distinction and the answer for the overlay case: `turbo_stream.refresh(method: :morph, scroll: :preserve)`, which re-renders nothing at the stream and asks Turbo to revisit the URL the browser already has — the one that still holds the state. The overlay still closes, because closing is what the stream response itself triggers. The one caveat is written down too: Turbo drops a refresh whose `X-Turbo-Request-Id` it has seen recently, and `Modal`/`Drawer` never send that header because they submit through plain `fetch` rather than `Turbo.fetch` — so a host that changes that has to go back to `replace` and send the listing's params along. The dummy's `/studios` now demonstrates the overlay shape instead of the broken one.

- **Two Cypress specs ignored `CYPRESS_BASE_URL` and tested somebody else's server.** `page-export-links.cy.js` and `direct-upload-controller.cy.js` visit the dummy app rather than a Lookbook preview, and both wrote out `http://localhost:3001`. `CYPRESS_BASE_URL` overrides the configured `baseUrl`, which governs relative paths only — an absolute URL in `cy.visit()` goes where it says. Running the suite from a git worktree, which needs its own port, therefore sent those two specs to a different checkout's code and database, where they *passed or failed* on the wrong thing; two earlier sessions chased that as an intermittent failure before finding the cause. Both now derive the origin from `new URL(Cypress.config('baseUrl')).origin`, so one variable governs all seventeen specs. The default in `cypress.config.cjs` is unchanged, so a run from the main checkout behaves exactly as before.


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

### Added

- **The shipping checklist for v3 is written down: a branch-tracking check, the six new Stimulus controllers, the real version floors and the lockstep rule.** Four gaps that only bite at the moment of release, and one of them was already true. `docs/guides/release-channels.md` gains the check that no consuming app tracks a branch — as the command that answers it, an org-wide sweep over `gh api repos/*/contents/Gemfile`, because the two shortcuts both lie: a local `grep` sees only the repos you have cloned, and `gh search code` returned **nothing** on 2026-08-03 while the sweep found four repos still on `branch: 'main'`. The same file now states the lockstep convention: the gem and the npm package move to the same tag, since a Gemfile on one version beside a `package.json` on another renders `data-controller` attributes no controller answers — silently.

  `docs/guides/migration-v2-to-v3.md` gains three things. A note for hosts that register controllers by hand, listing all **six** identifiers v3 adds (`alert`, `toast-container`, `kanban`, `side-menu-trigger`, `toolbar-overflow`, `export-links`) and the three that stop registering (`message`, `notification`, `table`) — the list was diffed out of the two `CONTROLLERS` maps rather than recalled, and `toolbar-overflow` and `export-links` in particular fail with no console output at all. A *Requirements* section replacing *Version floors*, with the floors read out of the gemspec and `package.json` and a column for who enforces each one, which is how you find out that daisyUI is enforced by nothing and Tailwind is declared by nobody — the latter on purpose, since Bali ships CSS source and the host's v4 build is the only Tailwind in the picture. And a table splitting what v2 deprecated and v3 removed outright (the `Bali::Link(type:)` and `Bali::Tag` Bulma names, which now raise) from what still warns through `Bali.deprecator` until 4.0.

  The `@blocknote` floor stays at `>= 0.52.1` and the guide now says why, along with the discrepancy behind it: `spec/dummy/yarn.lock` resolves 0.52.1 and CI installs it on every run, but `spec/dummy/node_modules` holds **0.46.2** and `.yarn-integrity` still records `^0.46.0`, so the last install here predates #759 and every by-hand pass over the editor since has been a pass over 0.46.2. Lowering the floor to match would re-open the data-loss bug that 0.51's synchronous serialisers fixed; what is missing is a `yarn install` and a human looking at the editor on the version the floor names.

- **`bali:modal:open` and `bali:drawer:open` can name the overlay they mean.** Both events now read an optional `detail.id`, and a controller answers only when that id matches its own template target's id; a trigger link can carry `data-modal-id` / `data-drawer-id` to the same effect. Without an id the event stays a broadcast handled by whichever overlay holds the targets, which is what every existing call site sends, so **nothing changes for a host that updates**. This is what makes more than one modal per page addressable: until now the only tiebreaker was to discard controllers lacking targets, which selects nothing when two candidates both have them. Note that the generated fallback ids are still not stable across renders (`modal-#{object_id}`, `drawer-#{SecureRandom.hex(4)}`), so addressing an overlay means passing `id:` / `drawer_id:` explicitly — the generated ones remain unaddressable by construction.


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

### Changed (breaking)

- **`submit_group`'s Cancel renders `btn-ghost` instead of `btn-secondary`.** Every form using `submit_group` with a `cancel_path:`, `cancel_options:`, `modal:` or `drawer:` repaints its Cancel — no call site changes, but the button changes weight, so it is listed here rather than under Fixed.

  The library was teaching two things at the same time. Every `FormPage` preview builds its actions row by hand and writes `variant: :ghost` on Cancel; `submit_group` — the helper those previews exist to promote — defaulted to `:secondary`. A form has one primary action, and a filled secondary sitting next to Submit reads as a second thing to do rather than as the way out of the form. Whichever of the two was right, shipping both meant the reference implementation and the helper disagreed on the page.

  An explicit class still wins: `cancel_options: { class: 'btn btn-secondary' }`. A test now pins that, next to the one that pins the new default.

- **`Modal` and `Drawer` are native `<dialog>` elements now, opened with `showModal()` — and everything the stacking scale ranked above them had to follow them into the top layer.** This is the last cut of #679; #784 modernised the interior and #796 made portaled popups survive a top-layer overlay, which was this change's precondition. The loading mechanism is untouched: `?layout=false`, the manual fetch, `_replaceBodyAndURL` and the contract of all 194 `drawer: true` / `modal: true` call sites are exactly as they were, per the 31/07 decision that DX parity is the acceptance criterion.

  **What the element buys.** `showModal()` paints the panel in the top layer, so no `z-index` in the document can cover it; it makes every node outside the panel inert, so the page behind stops taking clicks and stops being reachable by Tab without any focus trap of ours; and it restores focus to the trigger on close. What is kept hand-written is everything `<dialog>` knows nothing about — the remote load, the instant skeleton, the sequence number that discards an abandoned open, the unsaved-form prompt, and the popups that portal out of the panel.

  **The one that had to be got right is Escape.** A `<dialog>` answers Escape by itself, and its close knows nothing about the guard that gives the first Escape to an open flatpickr calendar. Every branch of `close()` that decides *not* to close now calls `preventDefault()` on the keydown — including the branch that swallows the key on the calendar's behalf, which previously returned without it because there was nothing to prevent. A `cancel` listener is the backstop for a close request that never was a keydown we saw (a platform back gesture, or Escape pressed with the focus inside an `<iframe>` in the panel); it cancels the native close and routes the gesture through the same guarded path, so an unsaved form is never discarded by the browser behind the component's back. Measured in a browser on `bali/drawer/dirty_form`: with the calendar open, the first Escape closes the calendar and leaves the drawer open and `:modal`; the second closes the drawer.

  **`role="dialog"` and `aria-modal="true"` are gone from both components.** Both are implicit on `<dialog>`, and the second was a claim static markup cannot keep: a panel rendered `active:` that no script has opened is not modal, whatever the attribute says. A panel rendered `active:` is promoted with `showModal()` when its controller connects, which is what makes a server-opened overlay behave like a user-opened one.

  **The stacking scale no longer orders these overlays, and three more things had to move.** The top layer is a sequence, not a scale: among themselves Modal, Drawer, Command and `ConfirmDialog` now stack by the order they were opened in, so the last one opened is on top regardless of tier. Everything the scale ranked *above* them had to join the top layer or become invisible and inert, and two did not before this change:

  - **The command palette** is a `<dialog>` of its own now — a wrapper inside the container holding the backdrop and the panel, so every Stimulus target stays in scope and a `trigger` slot stays where the page put it. `--bali-z-command: 500` used to be enough to open ⌘K over a modal; nothing in the document is any more.
  - **The toast stack** moves into the open overlay for as long as that overlay lasts and moves back out on close, driven by a new `toast-container` controller. The node travels but its id does not, so `turbo_stream.append "toast-notifications"` keeps landing in the same place. This is what keeps the ordinary failed-submit flow working: a 422 leaves the panel open by design, and the flash that arrives with it would otherwise be painted underneath and unclickable.

  Measured on `/z-stack`, the page that exists to check this, with a drawer and a modal open at once: before the fix `document.elementFromPoint` over the toast returned `DIV.drawer-header` and over the palette's panel returned `DIV.drawer-overlay`; after, each returns itself. What is *below* them in the scale needed nothing — a dropdown a modal covers is a dropdown nobody can reach anyway — and a tooltip triggered from the page behind an overlay stays covered on purpose, for the same reason.

  **What a host that updates will notice.** `Bali::Modal` renders `<dialog class="modal …">` where it rendered `<div>`, and `Bali::Drawer` renders `<dialog class="drawer-component …">`; a selector written as `div.modal` or `[role="dialog"]` against either stops matching, and CSS or tests keyed on those need the element name. The `modal-open` / `drawer-open` classes are unchanged and still carry the state, so anything keyed on those is unaffected. A drawer is kept rendered while closed (against the UA's `dialog:not([open])`) so the panel can still slide out, and its box is zero-sized, so nothing behind it becomes unclickable. Two overlays that used to stack by tier now stack by open order. `aria-modal` and `role` disappear from the markup.

- **`FeedbackWidget` composes `Bali::Drawer`, and its embed token stops travelling in a URL.** The component carried its own copy of a drawer — overlay, panel, slide-in transform, header, ✕, ARIA — none of which it now repeats: the panel is a `Bali::Drawer`, so the `<dialog>`, the top layer, Escape, the focus containment and the labelled header all arrive with it, and what is left in the component is the iframe and the token that goes into it. The embed's height stops being a header height written down a second time (`h-[calc(100%-49px)]`) and becomes a flex row scoped to this widget's own drawer, so no other drawer's layout changes.

  **The token moves from the query string to `postMessage`.** `?token=<JWT>` put a bearer credential in a URL, which is written to the server's access log, offered in the `Referer` of anything the embed loads, and kept in browser history. The frame's `src` is now the plain embed URL; the controller hands the token over once the frame has loaded, addressed to the embed's exact origin and never to `*`. **This is a coordinated change: an Opina instance that still reads the token from its query string will see an unauthenticated frame until it listens for `{ type: 'bali:feedback:token', token }` instead.** Verified end to end rather than asserted — `spec/dummy` serves a stand-in embed page at `/embed/feedback_posts` that prints whatever it was handed, and `/feedback-widget-demo` points a real widget at it: the frame loads with an empty query string and the token arrives by message.

  Two smaller consequences. The floating button's action is `feedback-widget#open`, not `#toggle`: while the drawer is open the rest of the page is inert, so the button is not clickable and a toggle-to-close was never reachable — the drawer's own ✕, overlay and Escape are the ways out. And because the drawer restores its markup on close, the embed reloads on each open instead of showing whatever it was holding the last time, which for a feed of feedback posts is the behaviour you wanted anyway.
- **One keyword for the icon: `icon:`, in every component that is handed the name of one.** `icon_name:` meant three different things at once. It was the current API on `Bali::Button`, `Bali::Link`, `Bali::Breadcrumb::Item` and `Bali::ImageField::Input`; it was the *deprecated* spelling on `Bali::StatCard` and `Bali::DeleteLink`; and on `Dropdown#with_item` it was whichever of those two the item turned out to be, because an item becomes a `Link` or a `DeleteLink` depending on `method:` and the lambda translated only in the second case — so whoever wrote the item could not tell which of the two APIs they were using. For a major whose theme is one API per concept (#691 unified `color:`, #682 the button taxonomy), that is the same collision #774 used to take `type:` away from `Link`.

  **Nothing breaks on upgrade, and the count is why.** `icon_name:` still works on all seven receivers, warns through `Bali.deprecator`, and is removed in 4.0. The eight applications that render this package were counted call site by call site, with a six-line window after each render so that a keyword on a continuation line is not missed: `Link` **386**, `Breadcrumb::Item` **188**, `StatCard` 74, `Dropdown#with_item` 30, `Button` 5, `DeleteLink` 2, `ImageField::Input` 0 — **685** in total, which makes this the largest single surface of the v3 migration; `text_field_group`, the FormBuilder helper that earned its own shim in #675, had 329. The one that is easy to miss is `Breadcrumb::Item`, because hardly any of those 188 name it: they are hashes inside the `breadcrumbs:` array of an `IndexPage`, `ShowPage`, `FormPage`, `DashboardPage` or `DocumentPage`, and a grep for `Breadcrumb` finds none of them. The recipe that does find them, along with the two spelling details that make it work, is in `docs/guides/migration-v2-to-v3.md`.

  **Traffic does not decide who gets the shim here, and that is a deliberate departure from #675.** There, seven renamed helpers nobody called were simply deleted, because calling a method that no longer exists raises `NoMethodError` and names itself. A keyword is not like that: every one of these signatures ends in `**options` and forwards the leftovers to the outer tag, so a deleted `icon_name:` comes back out as a literal `icon_name="camera"` attribute on the element — no icon drawn, nothing logged, nothing to grep. `ImageField::Input` therefore keeps the shim with zero measured call sites, because for a removed keyword the only signal is silence.

  **What a host that updates will notice besides the warnings.** Two public readers change name: `Bali::Link::Component#icon_name` and `Bali::ImageField::Input::Component#icon_name` are `#icon`. `Bali::DeleteLink::Component#icon_name` stays, because it is not the keyword but the resolved answer to "which icon do I draw", `true` included. On `Button` and `Link` the keyword now shares its name with the `with_icon` slot; they were always the same concept, the slot is the form that takes options, and the slot still wins when both are given. `Dropdown#with_item` loses its last translation — it built `Link::Component.new(icon_name: icon)` purely because `Link` did not accept `icon:` yet, and both branches now spell it the same way.

  **The seven deprecations are one deprecation now.** `Bali::DeprecatedIconName` is the single place the shim lives, replacing three near-identical private methods and three message constants, so the wording, the removal version and the behaviour cannot drift apart per component. All seven messages open with `<Component> \`icon_name:\` is deprecated`, which is what makes one grep of a host's logs find every one of them. `test/bali/deprecated_icon_name_test.rb` is the only place in the suite that writes the old spelling on purpose — the rest migrated in the same commit, so nothing else would notice a shim that stopped forwarding or stopped warning — and it walks the components by reflection, so a component that grows `icon_name:` without a shim fails there rather than in a host. The three per-component deprecation tests it replaces were deleted rather than kept: they asserted the same thing for three of the seven.

  **The demo app stops teaching what the library deprecates.** Every `icon_name:` in `spec/dummy` is gone, and so are the last four call sites of `Bali::Level` and `Bali::InfoLevel` — the dashboard's "Quick Actions" row and the revenue page's distribution header are the plain `flex justify-between items-center gap-4` their deprecation message prescribes, and the two figure rows are grids of `Bali::StatCard`, which is what `InfoLevel`'s message points at and what `DashboardPage#with_stat` renders. `rails test` no longer prints a deprecation from a dummy view; the ones it still prints all come from tests that exercise a deprecated path on purpose. The component index page now marks `Level` and `RichTextEditor` as deprecated with their replacements, and the accessibility guide's icon-button example goes back to `icon:` — #787 had corrected it *to* `icon_name:` against what worked then, and noted it would want revisiting when this landed.

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

- **Six components that showed information no screen reader could reach.** Each is a different way of saying the same thing on screen and nothing at all to the accessibility tree, and every claim below was read off the browser's own tree (`Accessibility.getFullAXTree` over CDP), not off the markup — an `aria-label` on the wrong element looks right in the HTML and never arrives.

  **`BooleanIcon` had no accessible name, and `nil` lied** (#753). It rendered one Lucide SVG and nothing else; Lucide ships its icons `aria-hidden`, so the node was anonymous and a table cell containing one announced as empty. Colour was the only remaining difference between true and false, which is also WCAG 1.4.1. Every state now renders an `sr-only` name beside the icon — "Yes" / "No" / "Not specified", in `bali_view.boolean_icon.*` — and the wrapper carries `aria-hidden="true"` so the icon is not a second, nameless node. **The value is ternary now.** `nil` used to collapse into `false` through `!!value` and announce "No", which states something the record does not say; it renders a neutral dash in `text-base-content/40` instead. If a host relied on `value: nil` painting a red ✗ — a column of nullable booleans where "not set" was meant to read as "no" — pass `value: false` explicitly. Everything else keeps the old coercion: a truthy non-boolean is still true. A new `label:` gives the cell a real name where the generic one is useless: "Yes" on its own says nothing about *what* is true.

  **`LabelValue` rendered a `<label>` with no control.** A label pointing at nothing is a label for nothing — the text and the value beside it were two unrelated nodes in the tree. It is now a single-pair `<dl>` with `<dt>`/`<dd>`, which reads as term and definition with no ARIA at all (confirmed in the tree as `DescriptionList` → `term "Name"` → `definition "Juan Perez"`). **The outer element changed from `<div>` to `<dl>` and the inner ones from `<label>`/`<div>` to `<dt>`/`<dd>`**, so a selector or test naming those elements — `div.mb-2`, `label.font-bold`, `.min-h-6` as a `div` — stops matching; the class names are all unchanged. Use `Bali::PropertiesTable` instead when the pairs form one set read top to bottom: it is a single `<table>` of `<th scope="row">` rows, so a screen reader gets table navigation over the whole set, where a run of LabelValues is a run of separate one-pair lists.

  **`Tabs` claimed to be a tab widget when it was navigation.** With `href:` on every tab the click leaves the page: there is no panel, so `role="tab"` promised an `aria-controls` target that does not exist and `aria-selected` described state the component does not own. When *every* trigger has an `href:`, it now renders `<nav aria-label>` with plain links and `aria-current="page"` on the active one — verified in the tree as `navigation "Section navigation"` with `link` children and zero `tab` nodes — and the `tabs` Stimulus controller is not attached, because there is nothing for it to switch. A new `label:` names the nav; two of them on one page need telling apart, and `bali_view.tabs.navigation` is the default. **Mixing the two now raises `ArgumentError` instead of rendering.** Half links leaving the page and half tabs owning a panel, inside one `role="tablist"` where every child claims to be a tab, is a combination ARIA does not describe; it used to render in silence. The message names the two ways out: give every tab an `href:`, or drop it from all of them and use `src:` for a panel that loads on demand. Tabs with panels are untouched — same `role="tablist"`/`tab`/`tabpanel`, same controller, same markup.

  **`Chart` was an unnamed canvas.** Everything Chart.js paints is pixels, and the fallback content inside the tag only surfaces when canvas itself is unsupported, so the accessibility tree had an anonymous node where the chart is. The canvas is now `role="img"` with a name: `aria_label:` if given, else the `title:`, else a translated generic (`bali_view.chart.default_label`) — an unnamed `role="img"` is announced as nothing, so a generic name beats none. A name is still not a number, which is what the new `data_table` slot is for: pass a real `<table>` and it renders `sr-only` beside the canvas, and it is the only way a screen reader user reads a value off the chart. `Bali::Chart::Preview#with_data_table` is the worked example.

  **`Heatmap` was a grid of empty cells.** The value lived only in a hover card, so keyboard and screen-reader users had no path to any number, and the axis labels were `<td>`s that associated with nothing. The x labels stay at the foot of the chart, where they always were, but are `<th scope="col">` now — a column header associates with its column wherever in the table it is written — the y labels are `<th scope="row">`, and each cell carries its value as `sr-only` text. Both axes therefore reach the cell as headers and the cell only owes the number. The spacer cells in the header row became `<td>` so every column has exactly one header; the corner cell stays a `<th>` because it names the y-label column. The axis labels pick up `font-normal` to keep the weight the `<td>` had — the visual result is identical, which was the constraint.

  **`Kanban` announced nothing when a card was dropped.** A drop moves the DOM and nothing else: focus stays where it was, no text changes, and a live region is the only channel the outcome can travel through. Each column's card stack is now `role="list"` with an `aria-label` carrying the count — `"To Do, 3 cards"`, and **`"Backlog, 0 cards"` for an empty column**, which previously had no badge, no cards and no name at all — and each card is `role="listitem"`. The board renders one `role="status" aria-live="polite"` region and listens for `bali:sortable-list:end`, so a drop announces "Design landing page moved to Done, position 1 of 2". Confirmed by dragging a card between columns for real and reading the tree afterwards; the sentence is a translated template (`bali_view.kanban.card_moved`) interpolated in JavaScript, because the interpolation happens in the browser. `Bali::Kanban::Card` takes a `label:` for boards whose cards lead with a date or an avatar rather than a title, and every card gains `role="listitem"`, so a selector naming a bare `.card` inside a column still matches but one asserting the absence of a `role` does not. Registering the new `kanban` Stimulus controller is automatic through `registerAll`; an app that registers controllers one by one needs to add it. **The board gains an outer `<div class="kanban-component">`** to hold the controller and the region — the grid used to be the root element, so a host that made the Kanban a flex or grid *item* is now positioning that wrapper instead; `class:` still lands on the grid, where it always did.

  **`SortableList`'s `bali:sortable-list:end` event carries more detail.** It used to dispatch `{ order, toListId }`, and `order` is the *source* list — SortableJS fires `onEnd` on the instance the item left — so a listener had no way to reach the destination. It now also carries `item`, `from`, `to`, `oldIndex` and `newIndex`. Purely additive; existing listeners are unaffected.

  **What this does not do, and it is visible.** The column's `aria-label` is rendered on the server, so after a client-side drop it is as stale as the count badge next to it — both say "3 cards" until the page re-renders. That is deliberate: making only the screen-reader label live would have it disagree with the number a sighted user is looking at, and the drop announcement already carries the new position and total. Hosts that PATCH through `update_url` and re-render get both refreshed together.

- **`DashboardPage` no longer caps itself at `max-w-screen-2xl`.** It was the only one of the five page components that overrode the shared `:full` default without a reason of form, and the cap came from v2. `FormPage`'s `:md` is different and stays: a single column of fields stretched across a wide screen is genuinely the wrong shape. A stats grid and a row of charts are the opposite — they are exactly the content that should take the width the app's own container gives them, and a component that overrules that container from the inside is deciding something the host already decided. `IndexPage`, `ShowPage` and `DocumentPage` never overrode it, so `max_width:` now means one thing across four of the five.

  **This is visible only above 1536px**, and only there: below the old cap the two render identically, so a screenshot at 1280px will report that nothing happened. A host that wants the cap back passes `max_width: :"2xl"` and gets exactly the previous markup. Nothing narrows anywhere — `:full` is `max-w-full`, which never reduces.

  The demo app is where it shows: `/admin`, `/admin/analytics` and `/admin/revenue` sit in a layout with no container cap, so at a 2056px viewport the dashboard body goes from 1536px to 1752px. And the other half of "full width by default" was not in the package at all — `spec/dummy/app/views/layouts/application.html.erb` passed `body_container: :contained` (`max-w-7xl`), which clips **from the outside** and wins: `/movies` and `/studios` declared `IndexPage`'s `:full` and were served at 1280px regardless. That default is now `:wide`, which is also what makes `/studios` and `/admin/studios` — the same page in two different layouts — finally measure the same. A page that wants a cap still asks for one with `content_for(:body_container) { "contained" }`.

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
