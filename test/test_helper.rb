# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

# SimpleCov is started in spec/dummy/config/boot.rb (before gems load)
# so that Coverage.start tracks lib/ files loaded during Rails boot.

require File.expand_path("../spec/dummy/config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rails/test_help"
require "view_component/test_helpers"
require "view_component/test_case"
require "capybara/minitest"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase
  # Process-based parallelization loses SimpleCov coverage for files loaded
  # during Rails boot (before fork). Skip parallelization for coverage runs;
  # default to parallel for speed during development.
  unless ENV["COVERAGE"]
    parallelize(workers: :number_of_processors)
  end
end

class ComponentTestCase < ViewComponent::TestCase
  include ComponentTestHelpers
  include Capybara::Minitest::Assertions
end

class FormBuilderTestCase < ViewComponent::TestCase
  include ComponentTestHelpers
  include Capybara::Minitest::Assertions

  # Assert that an HTML string contains an element matching a CSS selector.
  # Mirrors RSpec's `expect(html).to have_css(selector, **options)`.
  def assert_html(html, selector, text: nil, count: nil, visible: nil, **_opts)
    node = Capybara.string(html)
    opts = {}
    opts[:text] = text if text
    opts[:count] = count if count
    opts[:visible] = visible unless visible.nil?
    assert node.has_css?(selector, **opts),
      "Expected to find '#{selector}'#{text ? " with text '#{text}'" : ""} in:\n#{html&.[](0, 300)}"
  end

  def refute_html(html, selector, **opts)
    node = Capybara.string(html)
    refute node.has_css?(selector, **opts),
      "Expected NOT to find '#{selector}' in:\n#{html&.[](0, 300)}"
  end

  private

  def helper
    @helper ||= TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil)
  end

  def resource
    @resource ||= Movie.new
  end

  def builder
    @builder ||= Bali::FormBuilder.new(:movie, resource, helper, {})
  end
end
