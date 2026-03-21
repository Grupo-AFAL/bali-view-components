# frozen_string_literal: true

module Bali
  module FeedbackWidget
    class Component < ApplicationViewComponent
      # @param project_slug [String] The project slug in Opina (e.g., "gobierno-corporativo")
      # @param opina_url [String] Base URL of the Opina instance (e.g., "https://opina-staging.afal.mx")
      # @param token [String, nil] Pre-built JWT token for embed authentication
      # @param secret [String, nil] Opina shared secret to generate the token automatically
      # @param user_id [String, nil] User ID for token generation (required when using secret)
      # @param email [String, nil] User email for token generation (required when using secret)
      # @param title [String] Drawer header title (default: "Feedback")
      # @param token_expires_in [Integer] Token expiry in seconds (default: 3600 = 1 hour)
      # @param badge_interval [Integer] Polling interval in ms for badge count (default: 300000 = 5 min)
      def initialize(project_slug:, opina_url:, token: nil, secret: nil, user_id: nil, email: nil,
                     title: nil, token_expires_in: 3600, badge_interval: 300_000, **options)
        @project_slug = project_slug
        @opina_url = opina_url.chomp("/")
        @token = token || generate_token(secret, user_id, email, token_expires_in)
        @title = title
        @badge_interval = badge_interval
        @options = options
      end

      private

      attr_reader :project_slug, :opina_url, :token, :badge_interval, :options

      def display_title
        @title || I18n.t("bali.feedback_widget.title", default: "Feedback")
      end

      def open_label
        I18n.t("bali.feedback_widget.open", default: "Open feedback")
      end

      def close_label
        I18n.t("bali.feedback_widget.close", default: "Close")
      end

      def generate_token(secret, user_id, email, expires_in)
        raise ArgumentError, "Either token: or secret: (with user_id: and email:) is required" unless secret

        TokenGenerator.call(
          secret: secret,
          project_slug: project_slug,
          user_id: user_id,
          email: email,
          expires_in: expires_in
        )
      end

      def embed_url
        "#{opina_url}/embed/feedback_posts?token=#{token}"
      end

      def badge_url
        "#{opina_url}/api/v1/projects/#{project_slug}/badge"
      end

      def html_attributes
        {
          class: class_names("feedback-widget", options[:class]),
          data: {
            controller: "feedback-widget",
            feedback_widget_embed_url_value: embed_url,
            feedback_widget_badge_url_value: badge_url,
            feedback_widget_interval_value: badge_interval
          }
        }
      end
    end
  end
end
