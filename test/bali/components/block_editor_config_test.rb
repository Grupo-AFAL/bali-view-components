# frozen_string_literal: true

require "test_helper"

class BaliBlockEditorConfigTest < ComponentTestCase
  Config = Bali::BlockEditor::Config

  def test_wrap_accepts_nil_a_hash_and_a_config
    assert_equal Config.new, Config.wrap(nil)
    assert_equal "/ai", Config.wrap(ai_url: "/ai").ai_url
    assert_equal "/ai", Config.wrap("ai_url" => "/ai").ai_url

    config = Config.new(ai_url: "/ai")
    assert_same config, Config.wrap(config)
  end

  def test_wrap_rejects_anything_else
    error = assert_raises(ArgumentError) { Config.wrap("nope") }
    assert_match(/expects nil, a Config or a Hash/, error.message)
  end

  def test_upload_url_defaults_to_auto_so_nil_can_mean_uploads_off
    assert_equal :auto, Config.new.upload_url
    assert_nil Config.new(upload_url: nil).upload_url
  end

  def test_merge_returns_a_new_config_and_leaves_the_receiver_alone
    original = Config.new(ai_url: "/ai", multi_column: true)
    merged = original.merge(ai_url: "/other")

    assert_equal "/other", merged.ai_url
    assert_equal "/ai", original.ai_url, "merge must not mutate the receiver"
    assert merged.multi_column, "untouched keys survive the merge"
  end

  # The reason merge takes a Hash and not a Config: every attribute of a Config is
  # populated, so merging one would overwrite all twelve with defaults instead of
  # the one key the caller meant.
  def test_merge_only_touches_the_keys_the_hash_carries
    original = Config.new(comments: { url: "/c" }, export: true)
    merged = original.merge(ai_url: "/ai")

    assert_equal({ url: "/c" }, merged.comments)
    assert merged.export
  end

  def test_merge_ignores_keys_that_are_not_config_attributes
    merged = Config.new.merge(ai_url: "/ai", editable: false, nonsense: 1)

    assert_equal "/ai", merged.ai_url
    assert_equal Config::ATTRIBUTES.sort, merged.to_h.keys.sort
  end

  def test_merge_rejects_a_config
    assert_raises(ArgumentError) { Config.new.merge(Config.new) }
  end

  def test_merge_of_nothing_is_the_same_object
    config = Config.new(ai_url: "/ai")
    assert_same config, config.merge(nil)
    assert_same config, config.merge({})
  end

  def test_two_configs_with_the_same_attributes_are_equal
    assert_equal Config.new(ai_url: "/ai"), Config.new(ai_url: "/ai")
    refute_equal Config.new(ai_url: "/ai"), Config.new(ai_url: "/other")
    assert_equal Config.new(ai_url: "/ai").hash, Config.new(ai_url: "/ai").hash
  end
end
