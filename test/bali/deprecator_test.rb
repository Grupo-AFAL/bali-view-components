# frozen_string_literal: true

require "test_helper"

class BaliDeprecatorTest < ActiveSupport::TestCase
  def test_deprecator_announces_the_gem_and_its_removal_horizon
    assert_instance_of(ActiveSupport::Deprecation, Bali.deprecator)
    assert_equal("4.0", Bali.deprecator.deprecation_horizon)
    assert_equal("Bali", Bali.deprecator.gem_name)
  end

  # Registered so a host configures Bali's warnings with the same
  # config.active_support.deprecation it already uses for Rails' own.
  def test_deprecator_is_registered_with_the_host_application
    assert_same(Bali.deprecator, Rails.application.deprecators[:bali])
  end

  def test_simple_filter_warns_through_the_bali_deprecator
    message = capture_warning do
      Class.new(Bali::FilterForm) do
        simple_filter :status, collection: [ %w[Done done] ], blank: "All"
      end
    end

    assert_match(/simple_filter is deprecated/, message)
    assert_match(/filter_attribute :status/, message)
  end

  # The deprecated DSL keeps producing the same definition it always did —
  # hosts get a warning, not a behaviour change.
  def test_simple_filter_still_declares_the_filter
    form_class = Bali.deprecator.silence do
      Class.new(Bali::FilterForm) do
        simple_filter :status, collection: [ %w[Done done] ], blank: "All", type: :slim_select
      end
    end

    definition = form_class.defined_simple_filters.sole
    assert_equal(:status, definition[:attribute])
    assert_equal([ %w[Done done] ], definition[:collection])
    assert_equal("All", definition[:blank])
    assert_equal(:slim_select, definition[:type])
    assert_equal([], form_class.new(Movie.all, ActionController::Parameters.new).available_attributes)
  end

  private

  def capture_warning(&block)
    captured = []
    Bali.deprecator.behavior = ->(message, *) { captured << message }
    block.call
    captured.join("\n")
  ensure
    Bali.deprecator.behavior = :stderr
  end
end
