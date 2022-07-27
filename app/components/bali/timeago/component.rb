# frozen_string_literal: true

module Bali
  module Timeago
    class Component < ApplicationViewComponent
      attr_reader :datetime, :add_suffix, :refresh_interval, :include_seconds, :options

      def initialize(
        datetime, add_suffix: false, refresh_interval: 5000, include_seconds: true, **options
      )
        @datetime = datetime
        @refresh_interval = refresh_interval
        @include_seconds = include_seconds
        @add_suffix = add_suffix

        @options = prepend_class_name(options, 'timeago-component')
        @options = prepend_controller(options, 'timeago')
        @options = prepend_values(options, 'timeago', controller_values)
      end

      def call
        tag.time(**options)
      end

      private

      def controller_values
        {
          datetime: datetime.to_fs(:iso8601),
          'include-second': include_seconds,
          'refresh-interval': refresh_interval,
          'add-suffix': add_suffix,
          locale: I18n.locale
        }
      end
    end
  end
end
