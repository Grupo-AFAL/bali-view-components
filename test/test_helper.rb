# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch

  add_filter "test/"
  add_filter "spec/"
  add_filter ".github/"
  add_filter "lib/bali/version"

  add_group "Components", "app/components/bali"

  add_filter(/preview.rb/)

  # TODO: Re-enable minimum coverage once SimpleCov collation is configured
  # for parallel minitest. Individual workers only see partial coverage,
  # so the merged result underreports until proper collation is set up.
  # minimum_coverage line: 80
end

require File.expand_path("../spec/dummy/config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rails/test_help"
require "view_component/test_helpers"
require "view_component/test_case"
require "capybara/minitest"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)
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
