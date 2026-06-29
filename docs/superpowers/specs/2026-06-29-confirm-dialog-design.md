# Confirm Dialog — Design Spec

- **Date:** 2026-06-29
- **Status:** Approved (design)
- **Author:** Federico González + Claude

## Problem

Apps consuming Bali rely on the browser's **native** confirmation dialog. Today the
only place Bali triggers one is `Bali::DeleteLink`, which renders
`button_to ... data: { 'turbo-confirm': confirm_message }`
(`app/components/bali/delete_link/component.html.erb:9`). Turbo's default confirm
method calls `window.confirm()`.

This causes two problems:

1. **Not testable with Claude in Chrome.** `window.confirm` is a browser-chrome modal,
   not page DOM, so the extension cannot click Confirm/Cancel. Confirmations have to be
   handled manually during automated browser testing.
2. **Unfriendly appearance.** The native dialog is unstyled and inconsistent with the
   rest of the DaisyUI-based UI.

There is currently **no** confirm-method override anywhere in Bali's JS, so every
`data-turbo-confirm` across all AFAL apps falls through to the native dialog.

Note the scope of triggers: within the **Bali repo** itself, `DeleteLink` is the only
element emitting `data-turbo-confirm` (verified: 1 grep match, no legacy `data-confirm`).
The submit / approval confirmations users see in real apps come from the **consuming
apps**, which attach `data-turbo-confirm` to their own buttons, forms, and links. The
global override intercepts Turbo's confirm method, so it covers all of those
automatically — that breadth is exactly why a global override is preferred over a
per-use component.

## Goal

Bali ships a custom confirmation dialog that:

- Replaces the native dialog **globally** for all existing `data-turbo-confirm` usages,
  with zero changes at call sites.
- Renders as page DOM so Claude in Chrome can interact with it.
- Looks consistent with Bali (DaisyUI styling).
- Supports per-confirmation customization (title, variant, button labels).

## Non-Goals

- A programmatic `Bali.confirm(...)` JS API for non-Turbo actions. (Considered and
  deferred — YAGNI. The module is structured so it could be added later without rework.)
- Replacing or restyling `Bali::Modal`. This is a separate, self-contained dialog.
- A per-use `Bali::ConfirmDialog` ViewComponent. The global override covers the need.

## Approach (chosen)

**Global Turbo confirm override**, auto-enabled when the app registers Bali controllers.

Verified against the installed Turbo 8 source
(`spec/dummy/node_modules/@hotwired/turbo/dist/turbo.es2017-esm.js`):

```js
// turbo.es2017-esm.js:1157-1161
const confirmMethod = typeof config.forms.confirm === "function"
  ? config.forms.confirm
  : FormSubmission.confirmMethod;
const answer = await confirmMethod(confirmationMessage, this.formElement, this.submitter);
```

So:
- The override is assigned to `Turbo.config.forms.confirm`
  (`Turbo.setConfirmMethod` is deprecated in Turbo 8 — `turbo.es2017-esm.js:6273`).
- Signature: `(message, formElement, submitter)`.
- The result is `await`ed → returning a `Promise<boolean>` is fully supported.

### Why a native `<dialog>` (not a styled `<div>`)

Use the native `<dialog>` element with `dialog.showModal()`, styled with DaisyUI
`modal` / `modal-box` classes (same look as `Bali::Modal`):

- **Claude in Chrome:** native `<dialog>` content lives in the top layer as real DOM —
  the extension can click its buttons. This is the core fix for problem 1.
- **Accessibility for free:** `showModal()` provides focus trap, ESC-to-close,
  `aria-modal`, and a `::backdrop`. Less custom code to maintain than a div-based modal.

## Components

### 1. `confirm_dialog.js` (new)

Location: `app/assets/javascripts/bali/confirm/confirm_dialog.js`

Exports:

- `confirmDialog(message, formElement, submitter) => Promise<boolean>`
  - Matches Turbo's confirm signature.
  - Renders/reuses a singleton `<dialog class="modal">` appended to `document.body`.
  - Reads optional customization data-attributes (see contract below) from
    `submitter` first, then `formElement`.
  - `showModal()`, then resolves the promise: `true` on confirm click, `false` on
    cancel click, ESC, or backdrop click.
- `installConfirmDialog(options = {}) => void`
  - Assigns `confirmDialog` to `Turbo.config.forms.confirm`.
  - Guard: no-op if `window.BALI_DISABLE_CONFIRM_DIALOG` is truthy.
  - Guard: if `window.Turbo` is not present yet, register a one-time `turbo:load`
    listener to install when Turbo becomes available.
  - `options`: `{ acceptText, cancelText }` configure the default button labels
    (fallbacks when a call site provides none).

The singleton dialog is built once and reused; each call updates title, message,
button labels, and the variant class on the confirm button.

### 2. Data-attribute contract

Namespaced `data-bali-confirm-*` to avoid collisions with Turbo's own attributes.
Turbo ignores unknown `data-*`.

| Attribute | Effect | Default |
|---|---|---|
| `data-turbo-confirm` | message (existing; Turbo triggers the flow) | — |
| `data-bali-confirm-title` | dialog title | none (title hidden if absent) |
| `data-bali-confirm-variant` | `danger` / `warning` / `info` → confirm button color (`btn-error` / `btn-warning` / `btn-primary`) | `btn-primary` |
| `data-bali-confirm-accept` | confirm button label | `installConfirmDialog` option, then JS fallback |
| `data-bali-confirm-cancel` | cancel button label | `installConfirmDialog` option, then JS fallback |

Resolution order for each attribute: `submitter` → `formElement` → install option/default.

### 3. Auto-enable wiring

`app/frontend/bali/index.js`:

- `import { installConfirmDialog, confirmDialog } from '...confirm/confirm_dialog'`
- Re-export both (selective-import users + tests).
- Call `installConfirmDialog()` inside `registerAll(application)`.

Consuming apps already call `registerAll`, so the custom dialog is automatic — no
code change required in apps. Opt-out via `window.BALI_DISABLE_CONFIRM_DIALOG`.

### 4. `Bali::DeleteLink` update

- `component.html.erb`: add `data-bali-confirm-variant="danger"`, `data-bali-confirm-title`,
  `data-bali-confirm-accept`, `data-bali-confirm-cancel` to the `button_to` form data
  (alongside the existing `turbo-confirm`).
- `component.rb`: add helper(s) returning localized title/labels.
- Locales: add keys under `delete_link` in `es` and `en` for title, accept, cancel.

Result: a delete confirmation renders with a clearly destructive red confirm button
and a localized title.

## Data Flow

1. User clicks a delete button (or any `data-turbo-confirm` element).
2. Turbo's `FormSubmission` calls `Turbo.config.forms.confirm(message, formElement, submitter)`.
3. `confirmDialog` reads message + `data-bali-confirm-*`, populates and `showModal()`s
   the singleton `<dialog>`.
4. User clicks Confirm/Cancel (or ESC/backdrop) → promise resolves `true`/`false`.
5. Turbo proceeds with or aborts the submission accordingly.

## Error Handling / Edge Cases

- **Turbo not loaded yet:** `installConfirmDialog` defers via `turbo:load`.
- **App wants native dialog:** set `window.BALI_DISABLE_CONFIRM_DIALOG = true` before
  registering, or re-assign `Turbo.config.forms.confirm` afterward.
- **Confirm inside a Bali::Modal:** native `<dialog>` lives in the top layer, above the
  modal (`z-61`), so it stacks correctly.
- **Repeated calls:** singleton dialog is reused; never appends duplicates.
- **No title provided:** title element hidden; dialog still renders message + buttons.

## Testing

- **Cypress (critical, end-to-end):** visit a Lookbook preview that triggers a confirm.
  Assert `dialog.modal` appears. Cancel → no navigation/submission. Confirm → action
  proceeds. This is the whole point of the change, so it must be covered here.
- **Minitest:** `DeleteLink` renders the correct `data-turbo-confirm` and
  `data-bali-confirm-*` attributes (variant `danger`, localized title/labels).
- **Manual browser verification (mandatory per CLAUDE.md):** run `spec/dummy` (`bin/dev`),
  exercise the flow in a real browser, screenshot the styled dialog.

## Files

**New**
- `app/assets/javascripts/bali/confirm/confirm_dialog.js`
- Lookbook preview to demo + drive Cypress (e.g. under DeleteLink previews or a dedicated `confirm` preview)
- Cypress spec for the confirm flow

**Modified**
- `app/frontend/bali/index.js` (export + install in `registerAll`)
- `app/components/bali/delete_link/component.html.erb`
- `app/components/bali/delete_link/component.rb`
- DeleteLink locale files (`es`, `en`)

**No new CSS** — reuses DaisyUI `modal` classes already in the compiled build.

## Risks

- **Auto-enable changes existing apps' confirmation appearance** on the next Bali bump.
  Text and logic are unchanged; only the dialog UI differs. Documented in CHANGELOG;
  opt-out flag available.
- **Bundle:** one small module added to the core entry. Negligible.

## Coverage Audit (resolved)

Audited `afal-apps` and `gobierno-corporativo` (2026-06-29):

- Neither app uses rails-ujs in source (no `@rails/ujs`, no `Rails.start`); both on Turbo 8.
- No raw `data-confirm` attributes. Every `confirm:` usage (13 in afal-apps, 5 in
  gobierno-corporativo) is a keyword arg to a Bali component — either `DeleteLink`
  directly or `ActionsDropdown#with_item(method: :delete, confirm:)`, which delegates to
  `DeleteLink` (`app/components/bali/actions_dropdown/component.rb:14`). All emit
  `data-turbo-confirm`.
- **Conclusion:** the global `Turbo.config.forms.confirm` override covers 100% of both
  apps' confirmations. The parallel `Rails.confirm` override is NOT needed.

### Known out-of-scope gap

`Bali::TurboNativeApp::SignOut` calls `window.confirm()` directly in its own Stimulus
controller (`app/components/bali/turbo_native_app/sign_out/index.js:10`) — it does not
use the `data-turbo-confirm` flow, so the override does not affect it. This is a Turbo
Native (mobile webview) sign-out path; left as-is for this work. Could later be routed
through `confirmDialog` if desired.

## Open Questions

- Default button labels (`acceptText`/`cancelText`) finalize during implementation;
  DeleteLink supplies localized labels regardless.
