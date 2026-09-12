# frozen_string_literal: true

module Bali
  module QrCode
    class Preview < ApplicationViewComponentPreview
      # @param payload text
      # @param size number
      # @param level select { choices: [l, m, q, h] }
      # A QR code generated server-side and rendered as inline SVG — no
      # JavaScript, no image request.
      #
      # It needs the `rqrcode` gem, which Bali does **not** depend on. Add
      # `gem "rqrcode", "~> 3.1"` to the host's Gemfile; without it the component
      # raises `Bali::QrCode::Component::MissingDependency` with that same line.
      #
      # The code is always black on white, quiet zone included: a scanner reads
      # dark-on-light, and theme colours would break it under a dark theme.
      def default(payload: 'https://github.com/Grupo-AFAL/bali', size: 200, level: :m)
        render Bali::QrCode::Component.new(payload: payload, size: size, level: level.to_sym)
      end

      # @label Error Correction Levels
      # The same payload at every level. A denser level spends modules on
      # redundancy, so the code survives a dirtier or partly covered surface and
      # grows for the same payload — `:h` is what you want behind a logo overlay
      # or on something printed, `:m` for a screen.
      def error_correction_levels
        render_with_template
      end

      # @label With Label
      # The default accessible name is the generic "QR code", which says nothing
      # about what scanning it does. Pass `label:` whenever the surrounding
      # markup does not supply that — the SVG is `role="img"` and the label is
      # the only name it has.
      def with_label
        render Bali::QrCode::Component.new(
          payload: 'otpauth://totp/Bali:ada@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Bali',
          label: 'Scan with your authenticator app'
        )
      end
    end
  end
end
