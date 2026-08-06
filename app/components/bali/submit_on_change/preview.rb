# frozen_string_literal: true

module Bali
  module SubmitOnChange
    # The `submit-on-change` utility controller, which has no component of its own.
    # See docs/guides/controllers.md for the full catalog.
    class Preview < ApplicationViewComponentPreview
      # `data-inner-html` is what makes this preview a regression test and not a demo:
      # rich option markup forces SlimSelect to rewrite the native <select>, and that
      # rewrite dispatches a `change` on it while the widget is still initializing.
      # Without the connect guard the form submits before the user has touched anything.
      # Integer values because `form_records.select` is an integer column, so the widget
      # comes back showing whatever the last submit sent.
      OPTIONS = [
        ['Drama', 1, { 'data-inner-html' => '<span class="flex items-center gap-2">🎭 Drama</span>' }],
        ['Comedy', 2, { 'data-inner-html' => '<span class="flex items-center gap-2">😄 Comedy</span>' }],
        ['Horror', 3, { 'data-inner-html' => '<span class="flex items-center gap-2">👻 Horror</span>' }]
      ].freeze

      # @label Default
      # A select that submits immediately next to a text input that submits after the
      # `delay`. Both controls sit on the same form, on the same controller.
      #
      # The form GETs its own URL, so the query string below is the whole story: it is
      # empty until a control changes, and every submit rewrites it.
      def default
        render_with_template(
          template: "bali/submit_on_change/previews/default",
          locals: { model: form_record, options: Bali::SubmitOnChange::Preview::OPTIONS }
        )
      end
    end
  end
end
