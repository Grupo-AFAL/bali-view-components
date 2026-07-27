# frozen_string_literal: true

require "test_helper"

class BlockEditorHelperTest < ActionView::TestCase
  include Bali::BlockEditorHelper

  # The dummy app has no editor bundle (spec/dummy/app/assets/builds is a
  # build artifact), so resolve assets predictably instead of via Propshaft.
  def asset_path(name)
    "/assets/#{name.sub(".", "-digest.")}"
  end

  def test_block_editor_meta_tags_publishes_js_and_css_paths
    html = block_editor_meta_tags

    assert_html(html, 'meta[name="bali-block-editor-js"][content="/assets/editor-digest.js"]',
                visible: false)
    assert_html(html, 'meta[name="bali-block-editor-css"][content="/assets/editor-digest.css"]',
                visible: false)
  end

  def test_block_editor_meta_tags_honors_custom_asset_names
    html = block_editor_meta_tags(js: "rich.js", css: "rich.css")

    assert_html(html, 'meta[name="bali-block-editor-js"][content="/assets/rich-digest.js"]',
                visible: false)
    assert_html(html, 'meta[name="bali-block-editor-css"][content="/assets/rich-digest.css"]',
                visible: false)
  end

  def test_block_editor_meta_tags_omits_css_when_nil
    html = block_editor_meta_tags(css: nil)

    assert_html(html, 'meta[name="bali-block-editor-js"]', visible: false)
    refute_match(/bali-block-editor-css/, html)
  end

  def test_helper_is_exposed_to_host_app_views
    assert ApplicationController.helpers.respond_to?(:block_editor_meta_tags),
           "Expected the engine to expose block_editor_meta_tags to host controllers"
  end

  private

  def assert_html(html, selector, visible: false)
    node = Capybara.string(html)
    assert node.has_css?(selector, visible: visible),
           "Expected to find '#{selector}' in:\n#{html}"
  end
end
