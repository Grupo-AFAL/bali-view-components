# frozen_string_literal: true

module Bali
  module FeedbackWidget
    # Generates HS256 JWT tokens for Opina embed authentication.
    # Compatible with Opina's embed/base_controller token verification.
    class TokenGenerator
      def self.call(secret:, project_slug:, user_id:, email:, expires_in: 3600)
        new(secret:, project_slug:, user_id:, email:, expires_in:).call
      end

      def initialize(secret:, project_slug:, user_id:, email:, expires_in:)
        @secret = secret
        @project_slug = project_slug
        @user_id = user_id
        @email = email
        @expires_in = expires_in
      end

      def call
        segments = [ encode_segment(header), encode_segment(payload) ]
        signing_input = segments.join(".")
        signature = OpenSSL::HMAC.digest("SHA256", @secret, signing_input)

        "#{signing_input}.#{base64url(signature)}"
      end

      private

      def header
        { alg: "HS256", typ: "JWT" }
      end

      def payload
        {
          sub: @user_id,
          email: @email,
          project_slug: @project_slug,
          exp: (Time.current + @expires_in).to_i
        }
      end

      def encode_segment(data)
        base64url(data.to_json)
      end

      def base64url(str)
        Base64.urlsafe_encode64(str, padding: false)
      end
    end
  end
end
