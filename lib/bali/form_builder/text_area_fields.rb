# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # El de Rails, para que la implementación pueda vivir bajo el nombre canónico
    # `text_area_field` en vez de esconderse dentro del override. Se liga por la superclase y
    # no con `alias`: ver la nota larga en `file_fields.rb` — con `alias`, un reload de código
    # re-capturaba el override de Bali y esto se llamaba a sí mismo (#840).
    define_method(:rails_text_area, superclass.instance_method(:text_area))

    module TextAreaFields
      # Moved to `HtmlUtils::COUNTER_CLASS` when `char_counter:` stopped being a
      # textarea-only option (#723). Kept as an alias because it is a public
      # constant a host may have referenced.
      COUNTER_CLASS = HtmlUtils::COUNTER_CLASS

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

      # The counter and auto-grow wrapper is `field_helper`'s `.control` div with
      # the controller on it — the two used to be built here, side by side with a
      # copy of the messages, which is how a textarea with a counter spent a
      # while rendering neither its help nor its error. One wrapper now, shared
      # with `text_field` (#723).
      def text_area_field(method, options = {})
        field_opts = textarea_field_options(method, options)

        field_helper(method, rails_text_area(method, field_opts), options)
      end
    end
  end
end
