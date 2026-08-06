# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationViewComponent
      STYLES = {
        default: "",
        bordered: "card-border",
        dash: "card-dash"
      }.freeze

      SIZES = {
        xs: "card-xs",
        sm: "card-sm",
        md: "",
        lg: "card-lg",
        xl: "card-xl"
      }.freeze

      renders_one :header, Header::Component

      renders_one :title, ->(text, **options) do
        tag.h2(text, class: class_names("card-title", options[:class]), **options.except(:class))
      end

      renders_one :image,
                  lambda { |src: nil, href: nil, alt: nil, figure_class: nil, **opts, &block|
                    if src.present?
                      Image::Component.new(
                        src: src, href: href, alt: alt, figure_class: figure_class, **opts
                      )
                    else
                      tag.figure(class: figure_class, **opts, &block)
                    end
                  }

      renders_many :actions, Action::Component

      # @param href [String, nil] Renders the card's root element as an `<a>` (daisyUI
      #   supports `<a class="card">`) with a hover shadow affordance. The card's content
      #   must not contain links or buttons then — interactive content inside an `<a>`
      #   is invalid HTML.
      def initialize(style: :default, size: :md, side: false, image_full: false, shadow: true,
                     body_class: nil, href: nil, **options)
        @style = style&.to_sym
        @size = size&.to_sym
        @side = side
        @image_full = image_full
        @shadow = shadow
        @body_class = body_class
        @href = href
        @options = options
      end

      private

      def root_tag
        @href.present? ? :a : :div
      end

      def card_attributes
        attrs = @options.merge(class: class_names(card_classes, @options[:class]))
        attrs[:href] = @href if @href.present?
        attrs
      end

      def card_classes
        class_names(
          "card",
          "bg-base-100",
          STYLES[@style],
          SIZES[@size],
          "card-side" => @side,
          "image-full" => @image_full,
          "shadow-sm" => @shadow,
          "transition-shadow hover:shadow-md" => @href.present?
        )
      end

      def render_body?
        content.present? || header? || title? || actions.any?
      end

      def body_classes
        class_names("card-body", @body_class)
      end
    end
  end
end
