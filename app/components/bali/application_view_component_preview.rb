# frozen_string_literal: true

module Bali
  class ApplicationViewComponentPreview < ViewComponentContrib::Preview::Base
    self.abstract_class = true

    include Pagy::Method

    def form_record
      @form_record ||= FormRecord.new
    end

    private

    # Pagy::Method requires a request object. Pagy::Request accepts a plain Hash
    # for non-Rack contexts like Lookbook previews.
    def request
      { base_url: "", path: "/lookbook", params: {}, cookie: nil }
    end
  end
end
