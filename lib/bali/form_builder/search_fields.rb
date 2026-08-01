# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SearchFields
      DEFAULT_BUTTON_CLASSES = "btn btn-neutral"

      def search_field_group(method, options = {})
        addon_class = options[:addon_class] || DEFAULT_BUTTON_CLASSES

        opts = options.with_defaults(
          placeholder: I18n.t("bali_view.form_builder.search.placeholder"),
          addon_right: search_addon(addon_class)
        )

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, opts) do
          text_field(method, opts)
        end
      end

      private

      # An icon is not a name: the SVG contributes no text, so this button was
      # announced as bare "button". The label is i18n'd because it is the only
      # thing a screen reader gets to read out here.
      def search_addon(button_class)
        tag.button(
          @template.render(Bali::Icon::Component.new("search")),
          type: "submit",
          class: button_class,
          'aria-label': I18n.t("bali_view.form_builder.search.submit")
        )
      end
    end
  end
end
