# frozen_string_literal: true

module Bali
  module ConfirmDialog
    # Bali replaces Turbo's native `window.confirm` with this styled `<dialog>`.
    # It applies to ANY element with `data-turbo-confirm` — not just deletes.
    # Customize per trigger with `data-bali-confirm-{title,variant,accept,cancel}`.
    class Preview < ApplicationViewComponentPreview
      def default
        render_with_template
      end
    end
  end
end
