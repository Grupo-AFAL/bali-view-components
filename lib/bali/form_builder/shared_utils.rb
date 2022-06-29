# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SharedUtils
      include HtmlUtils

      def label(method, text = nil, options = {}, &)
        options[:class] = "label #{options[:class]}"
        super(method, text, options, &)
      end

      def text_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end

      def number_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end
