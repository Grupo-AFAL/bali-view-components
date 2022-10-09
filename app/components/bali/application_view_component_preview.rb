# frozen_string_literal: true

module Bali
  class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
    self.abstract_class = true

    def form_record
      @form_record ||= FormRecord.new
    end
  end
end
