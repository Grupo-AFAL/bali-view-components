# frozen_string_literal: true

module Bali
  module Command
    # Command palette / launcher (⌘K-style). Renders a modal panel with grouped
    # search results, recents, and quick actions. Opens via:
    #   - Click on the trigger — a search-well button the component renders by
    #     default; the `with_trigger` slot REPLACES it when the shape has to be
    #     something else
    #   - Global ⌘K (Mac) / Ctrl+K (Windows/Linux) keyboard shortcut
    #   - Programmatically via the `bali:command:open` window event
    #
    # The default trigger is deliberately not a `.btn`: closing the palette with
    # Escape returns focus to the trigger, and daisyUI's focus-visible outline
    # around a bordered button reads as a double border. A filled well carries
    # no border of its own, so the focus ring is the only ring.
    #
    # Items can be pre-rendered (server-side) and filtered client-side via the
    # bundled Stimulus controller. Four group modes:
    #   - :searchable (default) — hidden until the query matches
    #   - :navigation          — the whole list on open, filtered as you type
    #   - :recent              — shown only when the query is empty
    #   - :action              — always shown (used as a fallback)
    class Component < ApplicationViewComponent
      DENSITIES = %i[default compact].freeze

      # What the shortcut hint says before JavaScript runs. The Stimulus
      # controller rewrites it to "Ctrl K" on a machine that is not a Mac: the
      # key the user has to press is a property of the keyboard in front of
      # them, and the server has no honest way to know it — sniffing the
      # User-Agent becomes a lie the moment the page is cached or served from
      # a CDN.
      AUTO_SHORTCUT_LABEL = "⌘K"

      renders_one :trigger
      renders_many :groups, lambda { |name:, mode: :searchable, **opts|
        Group::Component.new(name: name, mode: mode, **opts)
      }

      # @param trigger [Boolean] `false` renders no trigger at all — for a
      #   palette mounted globally and opened only via ⌘K or the
      #   `bali:command:open` event. The default trigger is new in v3; a host
      #   that rendered a trigger-less palette before it existed opts out here.
      # @param placeholder [String] Search input placeholder.
      # @param trigger_label [String] Text of the default trigger. Independent
      #   of `placeholder:` on purpose — the trigger is usually shorter than the
      #   input's invitation ("Search…" vs "Search movies, studios, actions…").
      #   Ignored when a `with_trigger` slot is given. For an icon-only trigger
      #   use the slot, not an empty label.
      # @param shortcut_label [Symbol, String, nil] Display label for the
      #   shortcut hint. `:auto` (the default) renders ⌘K and lets the Stimulus
      #   controller correct it to "Ctrl K" off a Mac — a Windows user has no ⌘
      #   key to press, and a hint pointing at one is worse than no hint. A
      #   String is rendered literally and never rewritten; nil hides the hint.
      #   The binding itself is ⌘K on Mac / Ctrl+K elsewhere — both chords work
      #   on both platforms, only the label picks a side.
      # @param density [Symbol] :default (44px rows) or :compact (32px rows).
      # @param no_results_text [String] Heading when the query has no matches.
      # @param no_results_subtitle [String, nil] Optional secondary line.
      def initialize(
        trigger: true,
        placeholder: nil,
        trigger_label: nil,
        shortcut_label: :auto,
        density: :default,
        no_results_text: nil,
        no_results_subtitle: nil,
        **options
      )
        @render_trigger = trigger
        @placeholder = placeholder || I18n.t("bali_view.command.placeholder")
        @trigger_label = trigger_label.presence || I18n.t("bali_view.command.trigger_label")
        # A Symbol here is a mode, and :auto is the only one there is. Left
        # unchecked a typo renders as the hint's text, in a kbd, forever.
        if shortcut_label.is_a?(Symbol) && shortcut_label != :auto
          raise ArgumentError,
                "Unknown shortcut_label #{shortcut_label.inspect} — pass :auto, a String, or nil"
        end

        @auto_shortcut = shortcut_label == :auto
        @shortcut_label = @auto_shortcut ? AUTO_SHORTCUT_LABEL : shortcut_label
        @density = DENSITIES.include?(density) ? density : :default
        @no_results_text = no_results_text || I18n.t("bali_view.command.no_results")
        @no_results_subtitle = no_results_subtitle
        @options = options
      end

      def compact?
        density == :compact
      end

      def render_trigger?
        @render_trigger
      end

      # Marks the hint as the component's own, so the controller knows it may
      # rewrite it. A label the host wrote stays exactly as the host wrote it.
      def auto_shortcut?
        @auto_shortcut
      end

      private

      attr_reader :placeholder, :trigger_label, :shortcut_label, :density,
                  :no_results_text, :no_results_subtitle, :options

      def container_classes
        class_names("bali-command", options[:class])
      end
    end
  end
end
