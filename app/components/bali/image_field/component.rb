# frozen_string_literal: true

module Bali
  module ImageField
    class Component < ApplicationViewComponent
      # An inline SVG, so the component renders nothing but itself.
      #
      # The comment here used to claim this was already a data URI while the
      # constant held `https://placehold.jp/128x128.png`. Every ImageField
      # without a `src:` — and every one *with* a `src:` too, since the
      # placeholder `<img>` is emitted alongside whenever there is an input
      # slot — fired a request at a third party on render: it leaked the page's
      # Referer, put a stranger's uptime in front of a form field, and left the
      # component broken behind an offline or egress-filtered network.
      #
      # Percent-encoded rather than base64 so it stays greppable, and so the
      # `#` of each hex colour cannot start a Ruby interpolation.
      DEFAULT_PLACEHOLDER_URL = "data:image/svg+xml;utf8," \
                                "%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22" \
                                "%20width%3D%22128%22%20height%3D%22128%22%20viewBox%3D%220%200" \
                                "%20128%20128%22%3E%3Crect%20width%3D%22128%22%20height%3D%22128" \
                                "%22%20fill%3D%22%23e5e7eb%22%2F%3E%3Ccircle%20cx%3D%2248%22%20" \
                                "cy%3D%2250%22%20r%3D%2210%22%20fill%3D%22%239ca3af%22%2F%3E" \
                                "%3Cpath%20fill%3D%22%239ca3af%22%20d%3D%22M28%2096l24-30%2016%2019" \
                                "%2012-14%2020%2025z%22%2F%3E%3C%2Fsvg%3E"
      private_constant :DEFAULT_PLACEHOLDER_URL

      SIZES = {
        xs: "size-16",
        sm: "size-24",
        md: "size-32",
        lg: "size-40",
        xl: "size-48"
      }.freeze

      DEFAULT_SIZE = :md
      private_constant :DEFAULT_SIZE

      renders_one :input, Bali::ImageField::Input::Component
      renders_one :clear_button

      attr_reader :size

      def initialize(src: nil, placeholder_url: DEFAULT_PLACEHOLDER_URL, size: DEFAULT_SIZE,
                     **options)
        @src = src || placeholder_url
        @placeholder_url = placeholder_url
        @size = size&.to_sym || DEFAULT_SIZE
        @options = options
      end

      private

      attr_reader :src, :placeholder_url, :options

      def container_classes
        class_names(
          "image-field-component",
          "group relative w-fit",
          options[:class]
        )
      end

      def container_options
        opts = options.except(:class)
        opts[:class] = container_classes
        prepend_controller(opts, "image-field")
      end

      def image_classes
        class_names(
          "rounded-lg object-cover",
          SIZES[size]
        )
      end

      def image_options
        {
          class: image_classes,
          data: { image_field_target: "output" },
          loading: "lazy",
          decoding: "async",
          alt: ""
        }
      end

      def placeholder_options
        {
          class: "hidden",
          data: { image_field_target: "placeholder" },
          loading: "lazy",
          decoding: "async",
          alt: ""
        }
      end

      def clear_button_classes
        class_names(
          "clear-image-button",
          "btn btn-circle btn-sm btn-ghost",
          "absolute -top-2 -right-2",
          "bg-base-200 text-base-content opacity-80",
          "hidden group-hover:flex max-md:flex"
        )
      end
    end
  end
end
