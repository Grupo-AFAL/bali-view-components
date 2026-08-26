# frozen_string_literal: true

require "test_helper"

class BaliWidgetFailureReportTest < ActiveSupport::TestCase
  class Stock < Bali::Widget::Base
    sized :medium
  end

  def error
    @error ||= StandardError.new("boom").tap { |e| e.set_backtrace(Array.new(9) { |i| "line #{i}" }) }
  end

  def report(widget = Stock.new) = Bali::Widget::FailureReport.new(error, widget: widget)

  # Tagged by key so an error reporter groups these per tile rather than piling
  # every widget's failure under one controller action.
  def test_tags_the_report_with_the_widget_key
    assert_equal "stock", report.tag
  end

  # `key` raises for an anonymous class, which is right for `key` — but this is
  # the reporting path, already inside a rescue, and raising here would mask the
  # failure it exists to record.
  def test_falls_back_to_a_name_when_the_widget_has_no_key
    anonymous = Class.new(Bali::Widget::Base) { sized :small }.new

    assert_equal "anonymous", report(anonymous).tag
  end

  def test_the_message_names_the_widget_the_class_and_the_reason
    message = report.message

    assert_includes message, "[bali/widget] stock failed to load"
    assert_includes message, "StandardError: boom"
  end

  # Enough frames to see which query raised, short enough that twelve failing
  # tiles do not bury the log.
  def test_the_backtrace_is_capped
    assert_equal 5, report.message.lines.count { |line| line.start_with?("line ") }
  end

  def test_a_missing_backtrace_does_not_take_the_reporter_down
    bare = Bali::Widget::FailureReport.new(StandardError.new("boom"), widget: Stock.new)

    assert_includes bare.message, "StandardError: boom"
  end

  # Through a real logger rather than a stub: `Rails.logger` is a
  # BroadcastLogger here, which does not take `stub`, and swapping in a plain
  # Logger over a StringIO tests the thing that actually runs.
  def test_record_writes_the_message_to_the_rails_logger
    output = StringIO.new
    original = Rails.logger
    Rails.logger = Logger.new(output)

    report.record

    assert_includes output.string, "[bali/widget] stock failed to load"
  ensure
    Rails.logger = original
  end
end
