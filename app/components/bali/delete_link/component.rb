# frozen_string_literal: true

module Bali
  module DeleteLink
    class Component < ApplicationViewComponent
      include Bali::DeprecatedIconName

      class MissingURL < StandardError; end

      # One table for Button, Link and DeleteLink. See Bali::ButtonTaxonomy — DeleteLink
      # used to take `size:` alone, capped at `lg`, with no way to ask for any other look.
      VARIANTS = Bali::ButtonTaxonomy::VARIANTS
      STYLES = Bali::ButtonTaxonomy::STYLES
      SIZES = Bali::ButtonTaxonomy::SIZES

      DEFAULT_VARIANT = :ghost

      # The variants with no colour of their own, and so the only ones that leave room for
      # the destructive red. `variant: :error` already paints the button red; adding
      # `text-error` on top of it would be red text on a red fill.
      COLOURLESS_VARIANTS = %i[ghost link].freeze

      DEFAULT_ICON = "trash"

      # The one component where `icon:` is not the old value under a new name: it also
      # takes `true`, which is what the pair `icon: true` + `icon_name: 'x'` collapsed into.
      ICON_HINT = "Here `icon:` takes an icon name as well as `true`."

      attr_reader :options, :disabled_hover_url

      # @param icon [Boolean, String, Symbol] `true` for the default trash icon, or the
      #   name of any other icon. Replaces the old `icon:` / `icon_name:` pair, where one
      #   said whether and the other said which.
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        model: nil,
        href: nil,
        name: nil,
        confirm: nil,
        variant: DEFAULT_VARIANT,
        style: nil,
        size: nil,
        disabled: false,
        disabled_hover_url: nil,
        skip_confirm: false,
        icon: false,
        icon_name: nil,
        authorized: true,
        plain: false,
        **options
      )
        @model = model
        @href = href
        @name = name
        @confirm = confirm
        @variant = (variant || DEFAULT_VARIANT).to_sym
        @variant_class = Bali::ButtonTaxonomy.variant!(self.class, @variant)
        @style_class = Bali::ButtonTaxonomy.style!(self.class, style)
        @size_class = Bali::ButtonTaxonomy.size!(self.class, size)
        @disabled = disabled
        @disabled_hover_url = disabled_hover_url
        @skip_confirm = skip_confirm
        @icon = icon.presence || deprecated_icon_name(icon_name, hint: ICON_HINT)
        @authorized = authorized
        @plain = plain
        # `button_to` puts a <form> around the button, and daisyUI styles `.menu li > *`
        # (`:not(.btn)` skips a button, not a form) — so inside a menu the FORM was the
        # item: it took the 6px/12px padding, the radius and the hover box, on top of the
        # 8px/10px `.menu .menu-item` already gave the button. Measured on
        # /lookbook/preview/bali/actions_dropdown/default: Delete 192x49 against Edit's
        # 192x37, with the clickable button inset to 168px and a second hover box inside
        # the first. `display: contents` takes the form out of the box tree and leaves the
        # button as the item — 192x37 @0,0, identical to a link item.
        #
        # It is asked for with `form_class: "contents"` and nothing else. It used to be
        # gated on `plain:`, on the premise that the keyword means "this DeleteLink is a
        # menu item"; it does not (#868). `plain:` is what the API says it is — a button
        # without the `.btn` box — and it travels far outside menus: the same Dropdown
        # builder hands it to `Link` too, `Breadcrumb::Item` passes it with no menu in
        # sight, and in afal-apps alone twelve `DeleteLink` carry it hand-written in the
        # action rows of show pages, none of them from `build_link_item`. Gated there,
        # `plain:` grew a second, undocumented meaning — "take my `<form>` out of the box
        # tree" — that a caller asking for the documented one never signed up for.
        # `inline-block` no va acá sino en delete_link/index.css, y su encabezado explica
        # por qué: como utilidad sobre el elemento empata con la que llegue por
        # `form_class:`, y el desempate lo gana la hoja compilada —medido, `.contents` se
        # emite ANTES que `.inline-block`— así que `form_class: "contents"` no hacía nada.
        @form_class = class_names("bali-delete-link-form", options.delete(:form_class))
        @options = options

        validate_url_presence!
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        @authorized
      end

      def authorized?
        @authorized
      end

      def href
        @href || @model
      end

      def name
        @name.presence || content.presence || t(".default_name")
      end

      def confirm_message
        return if @skip_confirm

        @confirm.presence || default_confirm_message
      end

      def confirm_data
        return {} if confirm_message.blank?

        {
          turbo_confirm: confirm_message,
          bali_confirm_variant: "danger",
          bali_confirm_title: t(".confirm_title"),
          bali_confirm_accept: t(".confirm_accept"),
          bali_confirm_cancel: t(".confirm_cancel")
        }
      end

      # The icon to draw, or nil for none. `true` means "the usual one".
      def icon_name
        return if @icon.blank?

        @icon == true ? DEFAULT_ICON : @icon.to_s
      end

      def disabled?
        @disabled
      end

      def button_classes
        if @plain
          class_names("flex items-center gap-2 text-error", @options[:class])
        else
          class_names(
            "btn",
            @variant_class,
            @style_class,
            @size_class,
            {
              "text-error" => COLOURLESS_VARIANTS.include?(@variant),
              "btn-disabled" => @disabled
            },
            @options[:class]
          )
        end
      end

      def form_classes
        @form_class
      end

      def button_options
        @options.except(:class)
      end

      private

      def default_confirm_message
        if @model.present?
          t(".specific_confirm_message", pronoun: pronoun, name: model_name)
        else
          t(".generic_confirm_message")
        end
      end

      def model_name
        @model.model_name.human
      end

      def pronoun
        t("activerecord.pronouns.#{@model.model_name.i18n_key}")
      end

      def validate_url_presence!
        return if @href.present? || @model.present?

        raise MissingURL, "Provide either :model or :href"
      end
    end
  end
end
