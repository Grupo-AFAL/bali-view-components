# frozen_string_literal: true

module Bali
  class ApplicationViewComponent < ViewComponentContrib::Base
    include HtmlElementHelper
    include PathHelper

    private

    def identifier
      @identifier ||= self.class.name.sub('::Component', '').underscore.split('/').join('--')
    end
  end
end
