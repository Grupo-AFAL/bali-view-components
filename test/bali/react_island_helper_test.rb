# frozen_string_literal: true

require "test_helper"

class ReactIslandHelperTest < ActionView::TestCase
  include Bali::ReactIslandHelper

  # The dummy app has no island bundles (spec/dummy/app/assets/builds is a
  # build artifact), so resolve assets predictably instead of via Propshaft.
  def asset_path(name)
    "/assets/#{name.sub(".", "-digest.")}"
  end

  def test_react_island_meta_tags_publishes_js_path
    html = react_island_meta_tags("gantt", js: "gantt.js")

    assert_html(html, 'meta[name="bali-gantt-js"][content="/assets/gantt-digest.js"]')
    refute_match(/bali-gantt-css/, html)
  end

  def test_react_island_meta_tags_publishes_css_path_when_given
    html = react_island_meta_tags("gantt", js: "gantt.js", css: "gantt.css")

    assert_html(html, 'meta[name="bali-gantt-js"][content="/assets/gantt-digest.js"]')
    assert_html(html, 'meta[name="bali-gantt-css"][content="/assets/gantt-digest.css"]')
  end

  def test_meta_names_match_what_the_generic_loader_derives
    # startIslandLoader(name) looks for meta[name="bali-<name>-js"] and
    # meta[name="bali-<name>-css"]; the helper must emit exactly those names.
    html = react_island_meta_tags("react-island-demo", js: "island-demo.js", css: "island-demo.css")

    assert_html(html, 'meta[name="bali-react-island-demo-js"]')
    assert_html(html, 'meta[name="bali-react-island-demo-css"]')
  end

  # block_editor_meta_tags is now a wrapper over this helper; its unchanged
  # output is pinned by test/bali/block_editor_helper_test.rb.

  def test_helper_is_exposed_to_host_app_views
    assert ApplicationController.helpers.respond_to?(:react_island_meta_tags),
           "Expected the engine to expose react_island_meta_tags to host controllers"
  end

  private

  def assert_html(html, selector)
    node = Capybara.string(html)
    assert node.has_css?(selector, visible: false),
           "Expected to find '#{selector}' in:\n#{html}"
  end
end
