# frozen_string_literal: true

module Bali
  module FeedbackWidget
    class Component < ApplicationViewComponent
      # The drawer's id, and with it the id of its title element, which the
      # component's accessible name has always been read from.
      DRAWER_ID = "feedback-widget"

      # @param project_slug [String] The project slug in Opina (e.g., "my-project")
      # @param opina_url [String] Base URL of the Opina instance (e.g., "https://opina.example.com")
      # @param token [String, nil] Pre-built JWT token for embed authentication
      # @param secret [String, nil] Opina shared secret to generate the token automatically
      # @param user_id [String, nil] User ID for token generation (required when using secret)
      # @param email [String, nil] User email for token generation (required when using secret)
      # @param user_name [String, nil] User display name for token generation (optional)
      # @param title [String] Drawer header title (default: "Feedback")
      # @param token_expires_in [Integer] Token expiry in seconds (default: 3600 = 1 hour)
      # @param badge_interval [Integer] Polling interval in ms for badge count (default: 300000 = 5 min)
      def initialize(project_slug:, opina_url:, token: nil, secret: nil, user_id: nil, email: nil,
                     user_name: nil, title: nil, token_expires_in: 3600, badge_interval: 300_000, **options)
        @project_slug = project_slug
        @opina_url = opina_url.chomp("/")
        @token = token || generate_token(secret, user_id, email, user_name, token_expires_in)
        @title = title
        @badge_interval = badge_interval
        @options = options
      end

      def drawer_id
        DRAWER_ID
      end

      def display_title
        @title || I18n.t("bali_view.feedback_widget.title")
      end

      def open_label
        I18n.t("bali_view.feedback_widget.open")
      end

      private

      attr_reader :project_slug, :opina_url, :token, :badge_interval, :options

      def generate_token(secret, user_id, email, user_name, expires_in)
        raise ArgumentError, "Either token: or secret: (with user_id: and email:) is required" unless secret

        TokenGenerator.call(
          secret: secret,
          project_slug: project_slug,
          user_id: user_id,
          email: email,
          user_name: user_name,
          expires_in: expires_in
        )
      end

      # No token in the query string. A URL is the one place a bearer credential
      # must not travel: it is written to the server's access log, offered in the
      # `Referer` of anything the embed loads, and kept in browser history. The
      # controller hands it to the frame with `postMessage` instead, addressed to
      # `embed_origin` and never to `*`.
      def embed_url
        "#{opina_url}/embed/feedback_posts"
      end

      # The exact origin `postMessage` is allowed to deliver to.
      def embed_origin
        uri = URI.parse(opina_url)
        origin = "#{uri.scheme}://#{uri.host}"
        origin += ":#{uri.port}" unless uri.port == uri.default_port
        origin
      end

      def badge_url
        "#{opina_url}/api/v1/projects/#{project_slug}/badge"
      end

      def html_attributes
        {
          class: class_names("feedback-widget", options[:class]),
          data: {
            controller: "feedback-widget",
            feedback_widget_drawer_id_value: drawer_id,
            feedback_widget_embed_url_value: embed_url,
            feedback_widget_embed_origin_value: embed_origin,
            feedback_widget_token_value: token,
            feedback_widget_badge_url_value: badge_url,
            feedback_widget_interval_value: badge_interval
          }
        }
      end
    end
  end
end
