# frozen_string_literal: true

module Bali
  module CheckboxToggle
    # The `checkbox-toggle` utility controller, which has no component of its own.
    # See docs/guides/controllers.md for the full catalog.
    class Preview < ApplicationViewComponentPreview
      # @label Required fields
      # An expense proved by its invoice, or by the school's receipts when the checkbox says
      # it is a public school's fee. Each side requires its file. With `disable-hidden` on,
      # the hidden side is a disabled fieldset: its file neither stops the form nor is sent,
      # as the query string below shows. Off, the hidden file keeps the form from sending.
      #
      # @param disable_hidden toggle
      def required_fields(disable_hidden: true)
        render_with_template(template: "bali/checkbox_toggle/previews/required_fields",
                             locals: { disable_hidden: disable_hidden })
      end
    end
  end
end
