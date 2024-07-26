# frozen_string_literal: true

module Bali
  module FormHelper
    include HtmlElementHelper

    # Adds the submit-button stimulus controller so that the Submit button
    # displays a spinner when clicked.
    def form_with(**options, &)
      prepend_controller(options, 'submit-button')

      super
    end
  end
end
