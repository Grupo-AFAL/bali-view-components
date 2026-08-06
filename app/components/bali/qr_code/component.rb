# frozen_string_literal: true

module Bali
  module QrCode
    # A QR code rendered server-side as inline SVG.
    #
    # The gem it encodes with, `rqrcode`, is deliberately *not* a dependency of
    # bali_view_components: three apps in the org render QR codes and the rest
    # would carry the gem for nothing. It is required the first time a component
    # actually builds a code, and its absence raises {MissingDependency} — a
    # LoadError subclass whose message names the line to add to the Gemfile.
    # Same contract as the optional npm peers in package.json.
    #
    # @example A URL
    #   render Bali::QrCode::Component.new(payload: movie_url(@movie))
    #
    # @example A TOTP enrolment code, named for the screen reader
    #   render Bali::QrCode::Component.new(
    #     payload: @totp.provisioning_uri, size: 240, level: :q,
    #     label: t('.scan_with_your_authenticator')
    #   )
    class Component < ApplicationViewComponent
      class MissingDependency < LoadError; end

      MISSING_DEPENDENCY_MESSAGE = <<~MSG.squish
        Bali::QrCode::Component needs the rqrcode gem, which bali_view_components
        does not depend on. Add `gem "rqrcode", "~> 3.1"` to your Gemfile and run
        `bundle install`.
      MSG

      # Error correction, cheapest to most redundant. A denser level survives a
      # dirtier or partially covered code by spending modules on redundancy, so
      # it also makes the code bigger for the same payload.
      LEVELS = %i[l m q h].freeze

      # The QR spec's quiet zone: four modules of background on every side. A code
      # rendered flush against its neighbours is a code some scanners will not
      # find, so it is not an option.
      QUIET_ZONE_MODULES = 4

      # Black on white, always. A scanner reads dark-on-light, and the theme's own
      # colours would leave the code unreadable the moment a host renders it under
      # a dark theme — which is exactly when it looks most like it works.
      FOREGROUND = "000"
      BACKGROUND = "fff"

      DEFAULT_SIZE = 200
      DEFAULT_LEVEL = :m

      # @param payload [String] What the code encodes — a URL, an otpauth: URI, plain text (required)
      # @param size [Integer] Rendered edge length in pixels. The SVG carries a
      #   viewBox, so a CSS class overrides it
      # @param level [Symbol] Error correction: :l, :m, :q or :h
      # @param label [String, nil] Accessible name. Defaults to the generic
      #   "QR code", which says nothing about what scanning it does — pass one
      #   whenever the surrounding markup does not
      # @param options [Hash] Additional HTML attributes for the svg element
      def initialize(payload:, size: DEFAULT_SIZE, level: DEFAULT_LEVEL, label: nil, **options)
        @payload = payload.to_s
        @size = size
        @level = validated_level(level)
        @label = label
        @options = prepend_class_name(options, "qr-code-component")

        raise ArgumentError, "Bali::QrCode::Component: payload is required" if @payload.empty?
      end

      def call
        tag.svg(**svg_attributes) { modules.html_safe }
      end

      private

      def validated_level(level)
        key = level.to_sym
        return key if LEVELS.include?(key)

        raise ArgumentError,
              "Bali::QrCode::Component: unknown level #{key.inspect}. " \
              "Valid: #{LEVELS.map(&:inspect).join(', ')}."
      end

      # `standalone: false` gets us the modules alone — the standalone form opens
      # with an XML declaration, which has no business inside an HTML document.
      # One module per user unit, so the offset counts modules and the viewBox
      # does the scaling.
      def modules
        qr_code.as_svg(
          standalone: false,
          use_path: true,
          module_size: 1,
          offset: QUIET_ZONE_MODULES,
          color: FOREGROUND,
          fill: BACKGROUND
        )
      end

      def svg_attributes
        {
          xmlns: "http://www.w3.org/2000/svg",
          viewBox: "0 0 #{extent} #{extent}",
          width: @size,
          height: @size,
          "shape-rendering": "crispEdges",
          role: "img",
          "aria-label": @label || I18n.t("bali_view.qr_code.label")
        }.merge(@options)
      end

      def extent
        qr_code.modules.size + (2 * QUIET_ZONE_MODULES)
      end

      def qr_code
        @qr_code ||= build_qr_code
      end

      def build_qr_code
        require "rqrcode"
        ::RQRCode::QRCode.new(@payload, level: @level)
      rescue ::LoadError
        raise MissingDependency, MISSING_DEPENDENCY_MESSAGE
      end
    end
  end
end
