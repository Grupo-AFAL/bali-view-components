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

  # The threads sidebar was read-only by CSS and by nothing else: three
  # `display: none !important` rules against a docs page that promised replies and
  # reactions from the panel, and a `.bn-thread-composer` styled ninety lines below
  # as though it were visible. Interactive is the default; read-only is a mode a
  # host asks for by name (#1111).
  def test_the_threads_sidebar_is_interactive_unless_asked_otherwise
    assert_equal :interactive, Config.new.comments_sidebar
    assert_equal :interactive, Config.new(comments: { url: "/c" }).comments_sidebar
    refute_predicate Config.new(comments: { url: "/c" }), :comments_sidebar_read_only?
  end

  def test_read_only_is_a_mode_the_host_can_ask_for
    config = Config.new(comments: { url: "/c", sidebar: :read_only })

    assert_equal :read_only, config.comments_sidebar
    assert_predicate config, :comments_sidebar_read_only?
  end

  def test_the_mode_reads_a_string_key_too
    assert_predicate Config.wrap(comments: { "sidebar" => "read_only" }), :comments_sidebar_read_only?
  end

  def test_an_unknown_mode_names_itself_instead_of_falling_back
    error = assert_raises(ArgumentError) do
      Config.new(comments: { sidebar: :readonly }).comments_sidebar
    end

    assert_match(/sidebar: :readonly.*is not a sidebar mode/, error.message)
    assert_match(/:interactive, :read_only/, error.message)
  end

  def test_two_configs_with_the_same_attributes_are_equal
    assert_equal Config.new(ai_url: "/ai"), Config.new(ai_url: "/ai")
    refute_equal Config.new(ai_url: "/ai"), Config.new(ai_url: "/other")
    assert_equal Config.new(ai_url: "/ai").hash, Config.new(ai_url: "/ai").hash
  end
end
