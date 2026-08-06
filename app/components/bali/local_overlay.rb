# frozen_string_literal: true

module Bali
  # The local mode of a modal/drawer trigger: `modal: { id: "health-modal", local: true }`
  # opens an overlay that is already rendered on the page — no fetch, the server-rendered
  # content stays as it is. The remote mode (`modal: true`, `modal: { id: }` with an href)
  # is untouched; `local: true` is what switches the Stimulus action from `modal#open`
  # (fetch the href) to `modal#openLocal` (dispatch the open event by name).
  #
  # `id:` is MANDATORY in local mode, and the validation lives here so every trigger
  # component enforces it the same way. The reason is #854: an open event that names no
  # overlay is a broadcast, and a broadcast is answered by every shared overlay on the
  # page — the one nobody closes afterwards stays in the top layer and leaves the whole
  # document inert. A local trigger without a name has no meaning that is not that bug.
  #
  # Shared by Bali::Link, Bali::Button and Bali::Dropdown::ActionItem. Link is the only
  # one that also keeps the remote mode — a button has no href to fetch.
  module LocalOverlay
    OVERLAY_KINDS = %i[modal drawer].freeze

    private

    # Normalizes what the `modal:` / `drawer:` keyword accepts: `true`, or a hash of
    # options (`{ size: }`, `{ id: }`, `{ id:, local: true }`).
    def normalize_overlay_options(value)
      value.is_a?(Hash) ? value.symbolize_keys : {}
    end

    def local_overlay?(overlay_options)
      overlay_options[:local].present?
    end

    def validate_local_overlay!(kind, overlay_options)
      return unless local_overlay?(overlay_options)
      return if overlay_options[:id].present?

      raise ArgumentError,
            "#{self.class}: `#{kind}: { local: true }` requires an `id:`. A local open " \
            "without an id would broadcast to every #{kind} on the page and the ones " \
            "nobody closes leave the page inert (#854)."
    end

    # The trigger side of the local mode, merged into the element's `data` hash:
    # the action and the attribute naming the overlay it opens.
    def add_local_overlay_data(data, kind, overlay_options)
      data[:action] = [ "#{kind}#openLocal", data[:action] ].compact.join(" ")
      data[:"#{kind}_id"] = overlay_options[:id]
    end

    # For the triggers that have no href — Bali::Button and the dropdown's button item.
    # Rejects the remote mode outright (there is nothing to fetch) and returns the
    # normalized options, validated.
    def validate_local_only_overlay!(kind, value)
      return {} if value.blank?

      overlay_options = normalize_overlay_options(value)

      unless local_overlay?(overlay_options)
        raise ArgumentError,
              "#{self.class}: `#{kind}:` on a button supports only the local mode — " \
              "`#{kind}: { id: \"...\", local: true }`. A button has no href to fetch; " \
              "use Bali::Link for the remote #{kind}."
      end

      validate_local_overlay!(kind, overlay_options)
      overlay_options
    end

    # Merges both kinds' trigger data into an existing `data` hash (or nil). Returns nil
    # when there is nothing to add and nothing was there, so `.compact` can drop the key.
    def local_overlay_trigger_data(existing_data, modal_options, drawer_options)
      return existing_data if Bali.native_app || (modal_options.blank? && drawer_options.blank?)

      data = existing_data&.dup || {}
      add_local_overlay_data(data, :modal, modal_options) if modal_options.present?
      add_local_overlay_data(data, :drawer, drawer_options) if drawer_options.present?
      data
    end

    # Whether a `with_item`-style options hash asks for a local overlay — what routes an
    # href-less dropdown item to a real `<button>` instead of an `<a>` with no href.
    def local_overlay_trigger?(options)
      OVERLAY_KINDS.any? { |kind| local_overlay?(normalize_overlay_options(options[kind])) }
    end
  end
end
