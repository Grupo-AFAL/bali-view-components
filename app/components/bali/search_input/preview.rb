# frozen_string_literal: true

module Bali
  module SearchInput
    class Preview < ApplicationViewComponentPreview
      FORM = Bali::Utils::DummyFilterForm.new

      def default
        render Bali::SearchInput::Component.new(form: FORM, method: :name)
      end

      def auto_submit
        render Bali::SearchInput::Component.new(form: FORM, method: :name, auto_submit: true)
      end
    end
  end
end
