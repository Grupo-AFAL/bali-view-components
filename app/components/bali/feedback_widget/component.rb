# frozen_string_literal: true

module Bali
  module FeedbackWidget
    class Component < ApplicationViewComponent
      # The drawer's id, and with it the id of its title element, which the
      # component's accessible name has always been read from.
      DRAWER_ID = "feedback-widget"

      TRIGGERS = %i[floating icon labeled].freeze

      # `:icon` and `:labeled` are `btn-sm`, the height of `Bali::Topbar::IconAction`.
      TRIGGER_CLASSES = {
        floating: "btn btn-primary btn-circle shadow-lg fixed bottom-6 right-6 z-50",
        icon: "btn btn-primary btn-sm btn-circle relative",
        labeled: "btn btn-primary btn-sm relative max-sm:btn-circle"
      }.freeze

      BADGE_CLASSES = {
        floating: "badge badge-sm badge-error absolute -top-1 -right-1",
        icon: "badge badge-xs badge-error absolute -top-1 -right-1",
        labeled: "badge badge-sm badge-error max-sm:badge-xs max-sm:absolute max-sm:-top-1 max-sm:-right-1"
      }.freeze

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
      # @param trigger [Symbol] the button that opens the panel. `:floating` (default) pins a
      #   round button to the bottom-right corner of the viewport. `:icon` and `:labeled` render
      #   where the component is rendered, sized for `Bali::Topbar`'s `with_action`: a round
      #   icon button, or the icon with the title beside it, which drops to the icon below `sm`.
      def initialize(project_slug:, opina_url:, token: nil, secret: nil, user_id: nil, email: nil,
                     user_name: nil, title: nil, token_expires_in: 3600, badge_interval: 300_000,
                     trigger: :floating, **options)
        @project_slug = project_slug
        @opina_url = opina_url.chomp("/")
        @token = token || generate_token(secret, user_id, email, user_name, token_expires_in)
        @title = title
        @badge_interval = badge_interval
        @trigger = validated_trigger(trigger)
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

      attr_reader :project_slug, :opina_url, :token, :badge_interval, :trigger, :options

      def validated_trigger(value)
        key = value&.to_sym
        return key if TRIGGERS.include?(key)

        raise ArgumentError,
              "#{self.class}: unknown trigger #{value.inspect}. Valid: #{TRIGGERS.map(&:inspect).join(', ')}."
      end

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

      def badge_read_url
        "#{badge_url}/read"
      end

      def unread_id
        "#{DRAWER_ID}-unread"
      end

      # The labeled trigger takes its name from its text, so the name always contains the
      # words on screen — a host's `title:` included, which `open_label` would not.
      def trigger_attributes
        {
          type: "button",
          class: TRIGGER_CLASSES.fetch(trigger),
          title: (open_label if trigger == :icon),
          data: { action: "feedback-widget#open", feedback_widget_target: "trigger" },
          aria: { label: (open_label unless trigger == :labeled), describedby: unread_id }
        }
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
            feedback_widget_read_url_value: badge_read_url,
            # `%{count}` is left for the controller's `showUnread` to fill in.
            feedback_widget_unread_label_value: I18n.t("bali_view.feedback_widget.unread"),
            feedback_widget_interval_value: badge_interval
          }
        }
      end
    end
  end
end
