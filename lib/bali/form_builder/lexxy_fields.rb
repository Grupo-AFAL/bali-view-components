# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module LexxyFields
      def lexxy_editor_group(method, options = {}, &)
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          lexxy_editor(method, options, &)
        end
      end

      def lexxy_editor(method, options = {}, &)
        value = object.respond_to?(method) ? object.public_send(method) : nil
        component_options = extract_lexxy_options(method, options)

        @template.render(
          Bali::Lexxy::Component.new(
            name: "#{object_name}[#{method}]",
            value: value.to_s.presence,
            **component_options
          ),
          &
        )
      end

      private

      def extract_lexxy_options(method, options)
        opts = options.slice(:placeholder, :toolbar, :attachments, :markdown,
                             :multi_line, :rich_text, :required, :disabled,
                             :autofocus, :preset)
        opts[:class] = 'input-error' if errors?(method)
        opts.compact
      end
    end
  end
end
