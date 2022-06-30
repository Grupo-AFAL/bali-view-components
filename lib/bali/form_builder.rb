# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    include HtmlElementHelper
    include SharedUtils
    include SharedDateUtils
    include Utils
    include HtmlUtils
    include FormHelper

    Dir.glob(File.join(File.dirname(__FILE__), 'form_builder', '*.rb')) do |file|
      include FormBuilder.const_get(File.basename(file, '.rb').camelize)
    end
  end
end
