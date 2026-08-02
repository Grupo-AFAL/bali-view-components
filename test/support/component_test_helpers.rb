# frozen_string_literal: true

module ComponentTestHelpers
  def movie_form_builder(resource = Movie.new)
    view_context = ActionController::Base.new.view_context
    Bali::FormBuilder.new("movie", resource, view_context, {})
  end

  # `Bali.deprecator` writes to stderr in the test environment, so a deprecated
  # component under test prints a warning on every render. These two give a test a
  # way to assert on the warning and a way to keep it out of the run's output.
  def capture_deprecation
    captured = []

    with_deprecator_behavior(->(message, *) { captured << message }) { yield }

    captured.first
  end

  def silence_deprecations(&block)
    Bali.deprecator.silence(&block)
  end

  def with_deprecator_behavior(behavior)
    previous = Bali.deprecator.behavior
    Bali.deprecator.behavior = behavior
    yield
  ensure
    Bali.deprecator.behavior = previous
  end
end
