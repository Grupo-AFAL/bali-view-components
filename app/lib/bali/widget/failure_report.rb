# frozen_string_literal: true

module Bali
  module Widget
    # Where a widget's failure goes when it is not allowed to reach the page.
    #
    #   Bali::Widget::FailureReport.record(error, widget: self)
    #
    # Its own object for one reason: inside `Base` this was two private methods
    # that nothing could reach, so the Sentry tagging and the log format were
    # entirely untested — the code that runs only when something has already gone
    # wrong was the least verified code in the contract.
    #
    # It is also the one place `Base` reached outside its own domain. Widget
    # loading is `Base`'s job; deciding what an error reporter wants is not.
    class FailureReport
      # Five frames: enough to see which query raised, short enough that twelve
      # failing tiles do not bury the log.
      BACKTRACE_LINES = 5

      def self.record(...) = new(...).record

      def initialize(error, widget:)
        @error = error
        @widget = widget
      end

      def record
        # `defined?` rather than a hard dependency: Sentry is a host's choice, and
        # a library that assumed it would break every app without it.
        Sentry.capture_exception(error, tags: { widget: tag }) if defined?(Sentry)
        Rails.logger.error(message)
      end

      def message
        "[bali/widget] #{tag} failed to load — #{error.class}: #{error.message}\n" \
          "#{error.backtrace&.first(BACKTRACE_LINES)&.join("\n")}"
      end

      # TAGGED BY WIDGET KEY so an error reporter groups these per tile rather
      # than piling every widget's failure under one controller action.
      #
      # `key` raises for an anonymous class, which is CORRECT for `key` — it is
      # the i18n scope and the persisted `widget_key`, where a silent fallback
      # would collide. But this is the reporting path, already inside a rescue,
      # and an exception here would mask the failure it exists to record.
      def tag
        widget.key
      rescue StandardError
        widget.class.name || "anonymous"
      end

      private

      attr_reader :error, :widget
    end
  end
end
