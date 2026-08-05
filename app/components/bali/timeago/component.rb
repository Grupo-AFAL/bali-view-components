# frozen_string_literal: true

module Bali
  module Timeago
    # Displays relative time ("5 minutes ago", "2 hours ago") that updates dynamically.
    #
    # Uses date-fns for localized relative time formatting with optional auto-refresh.
    #
    # @example Basic usage
    #   render Bali::Timeago::Component.new(created_at)
    #
    # @example With suffix ("5 minutes ago" vs "5 minutes")
    #   render Bali::Timeago::Component.new(updated_at, add_suffix: true)
    #
    # @example Auto-refresh every 30 seconds
    #   render Bali::Timeago::Component.new(last_seen_at, refresh_interval: 30000)
    #
    class Component < ApplicationViewComponent
      BASE_CLASSES = "timeago-component"
      CONTROLLER = "timeago"

      def initialize(datetime, add_suffix: false, refresh_interval: nil, include_seconds: true,
                     **options)
        @datetime = datetime
        @refresh_interval = refresh_interval
        @include_seconds = include_seconds
        @add_suffix = add_suffix
        @options = options
      end

      def call
        return blank_element if datetime.blank?

        tag.time(relative_time, **time_options)
      end

      private

      attr_reader :datetime, :add_suffix, :refresh_interval, :include_seconds, :options

      # A <time> is only valid with a machine-readable datetime, and there is none
      # to give, so a nil datetime renders a plain <span> carrying the same class.
      # It used to raise NoMethodError instead.
      def blank_element
        tag.span(t("bali_view.timeago.blank"), **options.except(:data).merge(class: time_classes))
      end

      # Rendered so the element is never blank before Stimulus connects — or at all,
      # if the host ships no JavaScript. The controller overwrites it with date-fns
      # output on connect, which is where the wording can differ slightly.
      def relative_time
        distance = time_ago_in_words(datetime, include_seconds: include_seconds)
        add_suffix ? t("bali_view.timeago.ago", time: distance) : distance
      end

      def time_options
        base_options = {
          class: time_classes,
          datetime: formatted_datetime,
          data: controller_data
        }

        # Merge custom classes and data attributes without mutating options
        custom_options = options.except(:class, :data)
        base_options.merge(custom_options)
      end

      def time_classes
        class_names(BASE_CLASSES, options[:class])
      end

      def formatted_datetime
        datetime.to_fs(:iso8601)
      end

      def controller_data
        base_data = {
          controller: CONTROLLER,
          "#{CONTROLLER}-datetime-value": formatted_datetime,
          "#{CONTROLLER}-include-seconds-value": include_seconds,
          "#{CONTROLLER}-refresh-interval-value": refresh_interval,
          "#{CONTROLLER}-add-suffix-value": add_suffix,
          "#{CONTROLLER}-locale-value": I18n.locale
        }.compact

        # Merge any custom data attributes
        options.fetch(:data, {}).merge(base_data)
      end
    end
  end
end
