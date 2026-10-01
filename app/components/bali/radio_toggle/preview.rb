# frozen_string_literal: true

module Bali
  module RadioToggle
    # The `radio-toggle` utility controller, which has no component of its own.
    # See docs/guides/controllers.md for the full catalog.
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # One radio group and three targets. The last target lists two values separated by
      # a comma, so it shows for either.
      #
      # @param status select { choices: [pickup, delivery, courier] }
      def default(status: "pickup")
        render_with_template(template: "bali/radio_toggle/previews/default", locals: { status: status.to_s })
      end

      # @label Dependent fields
      # A terminal census: what the form asks for depends on the status, and the photo of
      # the label only on "Damaged" plus "I can't find the serial number" — a condition
      # joined with `+`. With `disable-hidden` on, a hidden target's fields are disabled,
      # so the query string below shows only what was on screen when the form was sent.
      #
      # @param status select { choices: [working, damaged, lost] }
      def dependent_fields(status: "working")
        render_with_template(template: "bali/radio_toggle/previews/dependent_fields",
                             locals: { status: status.to_s })
      end
    end
  end
end
