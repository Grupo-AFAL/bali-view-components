# frozen_string_literal: true

module Bali
  module QrScanner
    class Preview < ApplicationViewComponentPreview
      # @param autostart toggle
      # @param camera select { choices: [environment, user] }
      # @param stop_on_scan toggle
      # @param highlight toggle
      # A camera viewfinder that decodes QR codes in the browser. The natural
      # pair of `Bali::QrCode`, which renders one server-side.
      #
      # **The previews open with `autostart: false`, which is not the
      # component's default.** With the real default (`true`) the camera
      # permission prompt fires the moment the preview loads, and again on every
      # reload — flip the toggle to see it. `autostart: false` is also the right
      # shape inside a modal or an unopened tab, and it is the better manners
      # generally: a permission prompt the visitor asked for is one they
      # understand.
      #
      # It needs the `qr-scanner` npm package, an **optional** peer Bali does not
      # bundle: `yarn add qr-scanner`. Without it the component renders the
      # "unavailable" panel and the console names the line to add.
      #
      # A camera is only reachable over **https, or http on localhost**. On any
      # other host over plain http the browser exposes no camera at all — which
      # arrives looking exactly like a device that has none.
      def default(autostart: false, camera: :environment, stop_on_scan: true, highlight: true)
        render Bali::QrScanner::Component.new(
          autostart: autostart,
          camera: camera.to_sym,
          stop_on_scan: stop_on_scan,
          highlight: highlight
        )
      end

      # @label With a listener
      # What a host actually writes. The component decodes and announces; it
      # never decides what a code means. Everything past that is one listener:
      #
      # ```js
      # document.addEventListener('bali:qr-scanner:scan', ({ detail }) => {
      #   document.querySelector('#token').value = detail.value
      #   document.querySelector('#token').form.requestSubmit()
      # })
      # ```
      #
      # `detail.value` is the decoded string. `detail.result` is the raw result
      # from qr-scanner, which also carries `cornerPoints`.
      #
      # Point the camera at any QR code — the panel below fills in with what it
      # read. Since `stop_on_scan` is on, the camera then releases and the
      # viewfinder offers "Scan again".
      def with_listener
        render_with_template
      end
    end
  end
end
