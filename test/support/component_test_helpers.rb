# frozen_string_literal: true

module ComponentTestHelpers
  def movie_form_builder(resource = Movie.new)
    view_context = ActionController::Base.new.view_context
    Bali::FormBuilder.new("movie", resource, view_context, {})
  end

  # Renders the block as if the host app had set `builder` as its default
  # (`config.action_view.default_form_builder`, which is what
  # `docs/guides/installation.md` recommends and what almost every app in the group
  # has switched on). It is the only way a test can exercise the path where an
  # internal `form_with` of the gem changed shape without anyone touching Bali (#1137).
  #
  # The previous value is ALWAYS restored: `ActionView::Base.default_form_builder` is a
  # global `cattr_accessor`, and leaving it set would change the markup of every other
  # test running afterwards in the same process.
  def with_default_form_builder(builder)
    previous = ActionView::Base.default_form_builder
    ActionView::Base.default_form_builder = builder
    yield
  ensure
    ActionView::Base.default_form_builder = previous
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
