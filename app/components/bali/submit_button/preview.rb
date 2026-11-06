# frozen_string_literal: true

module Bali
  module SubmitButton
    # The `submit-button` utility controller, which has no component of its own.
    # See the controllers guide for the full catalog.
    class Preview < ApplicationViewComponentPreview
      # @label Launcher (hold others)
      # A list of choices, each its own `button_to`, on one wrapper with `hold-others`:
      # once one is pressed the others wait, so a second tap while the first is still
      # working doesn't start a second action. The pressed button shows its own busy
      # text (`data-turbo-submits-with`, with the spinner off) and a `status` target
      # announces it. Each choice GETs this page with `?choice=…`.
      def launcher
        render_with_template(template: 'bali/submit_button/previews/launcher')
      end
    end
  end
end
