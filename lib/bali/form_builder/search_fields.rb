# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SearchFields
      DEFAULT_BUTTON_CLASSES = "btn btn-neutral"

      # The last helper still spelled the v2 way. #675 left it alone on purpose,
      # because #677 was rewriting this file at the same time; with that landed,
      # it joins the convention. Counted across the eight applications that
      # render this builder before renaming: **0 call sites**, so no shim —
      # `search_field_group` raises `NoMethodError`, the same treatment the seven
      # other untrafficked renames got.
      def search_group(method, **options)
        addon_class = options[:addon_class] || DEFAULT_BUTTON_CLASSES

        opts = options.with_defaults(
          placeholder: I18n.t("bali_view.form_builder.search.placeholder"),
          addon_right: search_addon(addon_class)
        )

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, opts) do
          text_field(method, opts)
        end
      end

      # There is deliberately no `search_field`. Rails already defines one, and
      # unlike `text_area` or `time_zone_select` — where the override renders the
      # same control the canonical Bali name does — taking this name over would
      # change what the two measured host call sites already calling it get: a
      # submit-button addon and a default placeholder neither asked for. The bare
      # control for a search box is `text_field`, which is what `search_group`
      # renders inside its own wrapper.

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
