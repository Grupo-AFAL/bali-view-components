# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # UrlFields provides URL input helpers with DaisyUI styling.
    # Supports addons for protocol prefixes (https://) and domain suffixes (.com).
    module UrlFields
      def url_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          url_field(method, options)
        end
      end

      def url_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end
