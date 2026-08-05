# frozen_string_literal: true

module Bali
  module BooleanIcon
    # A boolean rendered as an icon. The icon carries no accessible name of its
    # own — Lucide ships its SVGs `aria-hidden` — so every state also renders an
    # `sr-only` label. Without it a screen reader announces an empty table cell,
    # and colour is then the only thing separating the two states, which is also
    # WCAG 1.4.1.
    #
    # The value is ternary on purpose. `nil` is *missing data*, not `false`:
    # announcing "No" for a column nobody filled in states something the record
    # does not say.
    class Component < ApplicationViewComponent
      STATES = {
        true => { icon: "check-circle", class: "text-success", key: "true" },
        false => { icon: "times-circle", class: "text-error", key: "false" },
        nil => { icon: "minus", class: "text-base-content/40", key: "blank" }
      }.freeze

      # @param value [Boolean, nil] true, false, or nil for "not specified"
      # @param label [String, nil] Accessible name for this cell. Defaults to the
      #   generic Yes/No/Not specified, which is correct but context-free — pass
      #   a label whenever the surrounding markup does not supply the subject.
      # @param options [Hash] Additional HTML attributes passed to the wrapper div
      def initialize(value:, label: nil, **options)
        @value = coerce_to_ternary(value)
        @label = label
        @options = prepend_class_name(options, component_classes)
      end

      def call
        tag.div(**@options) do
          safe_join([ icon, sr_label ])
        end
      end

      private

      # nil stays nil; anything else collapses to a boolean, so a truthy
      # non-boolean (a string, an integer) keeps reading as true.
      def coerce_to_ternary(value)
        value.nil? ? nil : !!value
      end

      def state
        STATES[@value]
      end

      def icon
        render Bali::Icon::Component.new(state[:icon], class: "w-5 h-5", "aria-hidden": true)
      end

      def sr_label
        tag.span(@label || I18n.t("bali_view.boolean_icon.#{state[:key]}"), class: "sr-only")
      end

      def component_classes
        class_names("boolean-icon-component inline-flex", state[:class])
      end
    end
  end
end
