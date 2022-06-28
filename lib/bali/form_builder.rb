# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    include HtmlElementHelper
    include SharedFormBuilderUtils
    include Utils

    Dir.glob(File.join(File.dirname(__FILE__), 'form_builder_helpers', '*.rb')) do |file|
      include FormBuilderHelpers.const_get(File.basename(file, '.rb').camelize)
    end
  end
end
