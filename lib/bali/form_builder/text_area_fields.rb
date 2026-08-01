# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TextAreaFields
      # Not `fieldset-label` like the help and error messages: that class is a
      # flex container, and the counter needs `text-end` on a block to sit on the
      # right. It inherits the fieldset's small type the way it always did.
      COUNTER_CLASS = "text-base-content/70 text-end w-full"

      def text_area_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          text_area(method, options)
        end
      end

      def text_area(method, options = {})
        char_counter = options[:char_counter]
        auto_grow = options[:auto_grow]
        use_stimulus = char_counter || auto_grow

        field_opts = textarea_field_options(method, options, stimulus: use_stimulus)
        textarea_element = super(method, field_opts)

        if use_stimulus
          # The stimulus wrapper replaces `field_helper`'s `.control` div, so the
          # messages have to be appended here too — before, a textarea with a
          # counter or auto-grow silently rendered neither its help nor its error.
          wrap_with_stimulus(
            textarea_element, char_counter: char_counter, auto_grow: auto_grow
          ) + error_and_help(method, options)
        else
          field_helper(method, textarea_element, options)
        end
      end

      private

      def wrap_with_stimulus(textarea, char_counter:, auto_grow:)
        max_length = char_counter.is_a?(Hash) ? char_counter[:max] : 0

        wrapper_options = {
          class: "control",
          data: {
            controller: "textarea",
            'textarea-max-length-value': max_length,
            'textarea-auto-grow-value': auto_grow.present?
          }
        }

        content_tag(:div, wrapper_options) do
          counter = build_counter_element if char_counter
          safe_join([ textarea, counter ].compact)
        end
      end

      def build_counter_element
        content_tag(:p, "", class: COUNTER_CLASS, data: { 'textarea-target': "counter" })
      end
    end
  end
end
