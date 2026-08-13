# frozen_string_literal: true

module Bali
  # The Status namespace carries two module-level APIs next to the component:
  #
  # * `Bali::Status.palette(name)` — the fixed workflow palette as public API,
  #   for painting something that is NOT a pill (a Gantt bar, a chart slice)
  #   with the same colour the pill uses for the same state. Public means
  #   frozen: as of v3.1 changing one of the twelve pairs is a breaking change.
  # * `Bali::Status.for` — the enum sugar, mirror of `Bali::Tag.for`. Tag is
  #   for categories that follow the theme; Status is for workflow states with
  #   the fixed palette and the editable pill. docs/guides/enum-badges.md has
  #   the recipe and the criterion.
  module Status
    class << self
      # @param name [Symbol, String] one of the twelve palette names
      # @return [Hash] `{ bg:, fg: }` hex pair, contrast already resolved
      def palette(name)
        Component::PALETTE.fetch(name.to_s.to_sym) do
          raise ArgumentError,
                "Bali::Status.palette: unknown colour #{name.inspect}. " \
                "Valid: #{Component::PALETTE.keys.map(&:inspect).join(', ')}."
        end
      end

      # Returns a `Bali::Status::Component` for a domain value, building the
      # whole `options:` array from the map — which is what makes the same map
      # power the editable panel too:
      #
      #   render Bali::Status.for(task.status,
      #                           map: { pending: :slate, done: :green },
      #                           i18n_scope: "tasks.statuses",
      #                           form: { url: task_status_path(task), param: "task[status]" })
      #
      # @param value [Symbol, String, nil] the selected value; nil renders the
      #   placeholder pill
      # @param map [Hash] value => colour name, or value => hash of option keys
      #   (`{ color: }` / `{ custom_color: }`; `label:` overrides the label)
      # @param i18n_scope [String, nil] labels looked up as
      #   `"#{i18n_scope}.#{value}"`; without it each label is
      #   `value.to_s.humanize`
      # @param default [Symbol, Hash, nil] entry used when `value` is missing
      #   from the map, appended as one more option. Without it an unmapped
      #   value raises — a new domain state must be mapped, not rendered slate.
      # @param status_options extra `Bali::Status::Component` options (`form:`,
      #   `size:`, `readonly:`, `clearable:`, `id:`, ...)
      def for(value, map:, i18n_scope: nil, default: nil, **status_options)
        options = map.map { |key, entry| option_for(key, entry, i18n_scope) }
        options << unmapped_option(value, map, default, i18n_scope)
        Component.new(selected: value, options: options.compact, **status_options)
      end

      private

      def option_for(key, entry, i18n_scope)
        entry = entry.is_a?(Hash) ? entry.transform_keys(&:to_sym) : { color: entry }
        label = entry.delete(:label) || label_for(key, i18n_scope)
        { value: key.to_s, label: label, **entry }
      end

      def unmapped_option(value, map, default, i18n_scope)
        return if value.blank? || map.key?(value.to_s.to_sym) || map.key?(value.to_s)

        if default.nil?
          raise ArgumentError,
                "Bali::Status.for: #{value.inspect} is not in the map " \
                "(keys: #{map.keys.map(&:inspect).join(', ')}) and no `default:` was given."
        end

        option_for(value, default, i18n_scope)
      end

      def label_for(value, i18n_scope)
        return value.to_s.humanize if i18n_scope.nil?

        I18n.t("#{i18n_scope}.#{value}")
      end
    end
  end
end
