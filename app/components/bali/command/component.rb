# frozen_string_literal: true

module Bali
  module Command
    # Command palette / launcher (⌘K-style). Renders a modal panel with grouped
    # search results, recents, and quick actions. Opens via:
    #   - Click on the `with_trigger` slot (any button/input shape)
    #   - Global ⌘K (Mac) / Ctrl+K (Windows/Linux) keyboard shortcut
    #   - Programmatically via the `bali:command:open` window event
    #
    # Items can be pre-rendered (server-side) and filtered client-side via the
    # bundled Stimulus controller. Three group modes:
    #   - :searchable (default) — hidden until the query matches
    #   - :recent              — shown only when the query is empty
    #   - :action              — always shown (used as a fallback)
    class Component < ApplicationViewComponent
      DENSITIES = %i[default compact].freeze

      renders_one :trigger
      renders_many :groups, lambda { |name:, mode: :searchable, **opts|
        Group::Component.new(name: name, mode: mode, **opts)
      }

      # @param placeholder [String] Search input placeholder.
      # @param shortcut_label [String, nil] Display label for the shortcut hint
      #   (e.g. "⌘K"). Pass nil to hide the hint. The actual key binding is
      #   ⌘K on Mac / Ctrl+K elsewhere — handled in the Stimulus controller.
      # @param density [Symbol] :default (44px rows) or :compact (32px rows).
      # @param no_results_text [String] Heading when the query has no matches.
      # @param no_results_subtitle [String, nil] Optional secondary line.
      def initialize(
        placeholder: nil,
        shortcut_label: "⌘K",
        density: :default,
        no_results_text: nil,
        no_results_subtitle: nil,
        **options
      )
        @placeholder = placeholder || I18n.t("bali.command.placeholder", default: "Search…")
        @shortcut_label = shortcut_label
        @density = DENSITIES.include?(density) ? density : :default
        @no_results_text = no_results_text || I18n.t("bali.command.no_results", default: "No results")
        @no_results_subtitle = no_results_subtitle
        @options = options
      end

      def compact?
        density == :compact
      end

      private

      attr_reader :placeholder, :shortcut_label, :density,
                  :no_results_text, :no_results_subtitle, :options

      def container_classes
        class_names("bali-command", options[:class])
      end
    end
  end
end
