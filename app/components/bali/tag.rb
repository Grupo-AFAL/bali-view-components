# frozen_string_literal: true

module Bali
  # The Tag namespace also carries the enum-badge sugar: `Bali::Tag.for` turns
  # a domain value plus a host-owned map into a ready-to-render pill, so the
  # value → colour/icon table is declared once per enum instead of once per
  # call site. The map stays in the host on purpose — Bali knows how to paint
  # a category, not what your domain's categories are. The recipe (and when to
  # reach for `Bali::Status.for` instead) is in docs/guides/enum-badges.md.
  module Tag
    class << self
      # Returns a `Bali::Tag::Component` for a domain value, ready for `render`.
      #
      #   render Bali::Tag.for(ticket.priority,
      #                        map: { urgent: :error, low: :ghost },
      #                        i18n_scope: "tickets.priorities")
      #
      # @param value [Symbol, String, nil] the domain value (an enum, a state)
      # @param map [Hash] value => colour name, or value => hash of Tag options
      #   (`{ color:, icon:, style:, ... }`; `text:` overrides the label)
      # @param i18n_scope [String, nil] label looked up as
      #   `"#{i18n_scope}.#{value}"`; without it the label is
      #   `value.to_s.humanize`
      # @param default [Symbol, Hash, nil] entry used when `value` is missing
      #   from the map (same shapes as a map entry). Without it an unmapped
      #   value raises — a new domain state must be mapped, not rendered blank.
      # @param tag_options extra `Bali::Tag::Component` options (`size:`,
      #   `style:`, `href:`, ...); a key the entry also sets loses to the entry.
      def for(value, map:, i18n_scope: nil, default: nil, **tag_options)
        entry = entry_for(value, map, default)
        text = entry.delete(:text) || label_for(value, i18n_scope)
        Component.new(text: text, **tag_options, **entry)
      end

      private

      # Map keys are matched as written: symbol and string spellings both work,
      # so `enum` string values line up against a symbol-keyed map for free.
      def entry_for(value, map, default)
        entry = (map[value.to_s.to_sym] || map[value.to_s]) unless value.nil?
        entry ||= default

        if entry.nil?
          raise ArgumentError,
                "Bali::Tag.for: #{value.inspect} is not in the map " \
                "(keys: #{map.keys.map(&:inspect).join(', ')}) and no `default:` was given."
        end

        entry.is_a?(Hash) ? entry.transform_keys(&:to_sym) : { color: entry }
      end

      def label_for(value, i18n_scope)
        return value.to_s.humanize if i18n_scope.nil?

        I18n.t("#{i18n_scope}.#{value}")
      end
    end
  end
end
