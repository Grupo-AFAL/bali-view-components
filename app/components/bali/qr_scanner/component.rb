# frozen_string_literal: true

module Bali
  module QrScanner
    # A camera viewfinder that decodes QR codes in the browser and announces
    # each one as a DOM event.
    #
    # The natural pair of {Bali::QrCode::Component}, which renders a code
    # server-side: one app prints the label, another reads it.
    #
    # The decoding is done by the `qr-scanner` npm package, which Bali does
    # **not** bundle. It is an optional peer loaded with a dynamic `import()`
    # the first time a scanner connects; without it the component renders the
    # "unavailable" state and the console names the line to install. Same
    # contract as `rqrcode` on {Bali::QrCode::Component}.
    #
    # A camera is only reachable from a **secure context** — https, or http on
    # localhost. Over plain http on any other host `navigator.mediaDevices` is
    # undefined, which the browser reports in a way indistinguishable from a
    # machine with no camera, so the controller says so in the console.
    #
    # @example The default: start the camera on connect, stop on the first code
    #   render Bali::QrScanner::Component.new
    #
    # @example Ask before prompting — the right shape inside a modal or a tab
    #   render Bali::QrScanner::Component.new(autostart: false)
    #
    # @example Keep reading, front camera
    #   render Bali::QrScanner::Component.new(camera: :user, stop_on_scan: false)
    #
    # The host listens for `bali:qr-scanner:scan` and decides what a code means:
    #
    #   document.addEventListener('bali:qr-scanner:scan', ({ detail }) => {
    #     document.querySelector('#token').value = detail.value
    #   })
    class Component < ApplicationViewComponent
      CONTROLLER = "qr-scanner"

      # The two facing modes `getUserMedia` understands. `environment` is the
      # rear camera on a phone — the one pointed at the thing being scanned —
      # which is why it is the default.
      CAMERAS = %i[environment user].freeze
      DEFAULT_CAMERA = :environment

      # Every state the viewfinder can be in. `scanning` is the one with no
      # panel: the camera itself is the state.
      #
      # All the others render, always, and the controller shows one by taking
      # `hidden` off it. A state that is built on demand is a state nobody
      # styles and no test can find; this way a host restyles `denied` from a
      # stylesheet and a spec asserts on visibility rather than on text that
      # was never in the document.
      STATES = %i[idle requesting scanning scanned denied unavailable].freeze

      # The states that own a panel, in paint order.
      PANELS = (STATES - %i[scanning]).freeze

      def initialize(camera: DEFAULT_CAMERA, autostart: true, stop_on_scan: true,
                     highlight: true, hint: nil, **options)
        @camera = validated_camera(camera)
        @autostart = autostart
        @stop_on_scan = stop_on_scan
        @highlight = highlight
        @hint = hint
        @options = options
      end

      # The state the server renders. With `autostart:` the controller moves off
      # it the moment it connects; without JavaScript it is what the visitor is
      # left looking at, so it has to be the one that explains itself.
      def initial_state
        @autostart ? :requesting : :idle
      end

      def hint
        return if @hint == false

        @hint.presence || I18n.t("bali_view.qr_scanner.hint")
      end

      private

      attr_reader :camera, :autostart, :stop_on_scan, :highlight, :options

      def validated_camera(value)
        key = value.to_sym
        return key if CAMERAS.include?(key)

        raise ArgumentError,
              "Bali::QrScanner::Component: unknown camera #{key.inspect}. " \
              "Valid: #{CAMERAS.map(&:inspect).join(', ')}."
      end

      def panel_label(state, key)
        I18n.t("bali_view.qr_scanner.#{state}.#{key}")
      end

      def container_attributes
        attrs = options.except(:class, :data)
        attrs[:class] = class_names("qr-scanner-component", options[:class])
        attrs[:data] = (options[:data] || {}).merge(
          controller: CONTROLLER,
          qr_scanner_state: initial_state,
          qr_scanner_camera_value: camera,
          qr_scanner_autostart_value: autostart,
          qr_scanner_stop_on_scan_value: stop_on_scan,
          qr_scanner_highlight_value: highlight
        )
        attrs
      end

      # `playsinline` and `muted` are what stop iOS Safari from taking the
      # preview fullscreen the moment it plays. qr-scanner sets both itself, but
      # only once it has loaded — in the markup they are true before that.
      def video_attributes
        {
          class: "qr-scanner-video",
          playsinline: true,
          muted: true,
          disablepictureinpicture: true,
          data: { qr_scanner_target: "video" }
        }
      end

      def panel_attributes(state)
        {
          class: class_names("qr-scanner-panel", "hidden" => state != initial_state),
          data: { qr_scanner_target: "panel", qr_scanner_panel: state }
        }
      end
    end
  end
end
