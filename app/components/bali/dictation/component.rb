# frozen_string_literal: true

module Bali
  module Dictation
    # The mic and the line that says the dictation did not happen — the two pieces the
    # `speech-input` controller drives, written ONCE.
    #
    # Two callers render them: the FormBuilder's `dictation:` option and
    # `Chat::Composer::Component`. They used to carry a copy each, and the copies had already
    # drifted apart in the button size, the icon size and the status line's margin.
    #
    # Both go inside the element carrying the controller. WHERE inside is the caller's: the
    # form field hangs the mic off the corner of its own box, the composer puts it in the row
    # next to send. Hence `button_class:`.
    class Component < ApplicationViewComponent
      PARTS = %i[all button status].freeze

      # @param part [Symbol] `:all`, or `:button` / `:status` when the caller needs them in two
      #   different places — the composer puts the mic in its row of controls and the line
      #   underneath it, which is not a wrapper the component can invent for it.
      # @param button_class [String, nil] Where the mic sits. The caller's, because only it
      #   knows what the mic is sitting next to.
      # @param status_class [String, nil] Extra classes for the status line.
      def initialize(part: :all, button_class: nil, status_class: nil)
        raise ArgumentError, "part must be one of #{PARTS.join(", ")}" unless PARTS.include?(part)

        @part = part
        @button_class = button_class
        @status_class = status_class
      end

      private

      attr_reader :part, :button_class, :status_class

      def button? = part != :status

      def status? = part != :button

      def label = I18n.t("bali_view.form_builder.dictation.dictate")

      def unavailable = I18n.t("bali_view.form_builder.dictation.unavailable")

      def status_classes = class_names("fieldset-label", status_class)
    end
  end
end
