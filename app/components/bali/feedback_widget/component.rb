# frozen_string_literal: true

module Bali
  module FeedbackWidget
    class Component < ApplicationViewComponent
      attr_reader :project_slug, :opina_url, :token, :badge_interval

      # @param project_slug [String] The project slug in Opina (e.g., "gobierno-corporativo")
      # @param opina_url [String] Base URL of the Opina instance (e.g., "https://opina-staging.afal.mx")
      # @param token [String] Short-lived JWT token for embed authentication
      # @param badge_interval [Integer] Polling interval in ms for badge count (default: 300000 = 5 min)
      def initialize(project_slug:, opina_url:, token:, badge_interval: 300_000, **options)
        @project_slug = project_slug
        @opina_url = opina_url.chomp("/")
        @token = token
        @badge_interval = badge_interval
        @options = options
      end

      private

      def embed_url
        "#{opina_url}/embed/feedback_posts?token=#{token}"
      end

      def badge_url
        "#{opina_url}/api/v1/projects/#{project_slug}/badge"
      end

      def html_attributes
        {
          class: class_names("feedback-widget", @options[:class]),
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
