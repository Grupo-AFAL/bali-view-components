# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # El de Rails, para que la implementación pueda vivir bajo el nombre canónico
    # `text_area_field` en vez de esconderse dentro del override. Se liga por la superclase y
    # no con `alias`: ver la nota larga en `file_fields.rb` — con `alias`, un reload de código
    # re-capturaba el override de Bali y esto se llamaba a sí mismo (#840).
    define_method(:rails_text_area, superclass.instance_method(:text_area))

    module TextAreaFields
      # Not `fieldset-label` like the help and error messages: that class is a
      # flex container, and the counter needs `text-end` on a block to sit on the
      # right. It inherits the fieldset's small type the way it always did.
      COUNTER_CLASS = "text-base-content/70 text-end w-full"

      def text_area_group(method, **options)
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          text_area_field(method, options)
        end
      end

      # Rails already owns the name `text_area`, and Rails, its form helpers and
      # any gem that builds on them call it positionally. So the canonical Bali
      # name is `text_area_field` — the `<type>_field` half of the pair — and the
      # override keeps its Rails signature and simply forwards. Nothing a host
      # already wrote stops working, and `f.text_area` keeps rendering the styled
      # textarea rather than quietly falling through to Rails' bare one.
      def text_area(method, options = {})
        text_area_field(method, options)
      end

      def text_area_field(method, options = {})
        char_counter = options[:char_counter]
        auto_grow = options[:auto_grow]
        use_stimulus = char_counter || auto_grow

        field_opts = textarea_field_options(method, options, stimulus: use_stimulus)
        textarea_element = rails_text_area(method, field_opts)

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
