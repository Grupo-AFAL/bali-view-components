# frozen_string_literal: true

module Bali
  module SearchInput
    class Preview < ApplicationViewComponentPreview
      # @param auto_submit toggle "Auto-submit on input change"
      # @param placeholder text "Custom placeholder text"
      def default(auto_submit: false, placeholder: nil)
        form = Bali::Utils::DummyFilterForm.new
        render Bali::SearchInput::Component.new(
          form: form,
          field: :name,
          auto_submit: auto_submit,
          placeholder: placeholder.presence
        )
      end
    end
  end
end
