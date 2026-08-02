# frozen_string_literal: true

require "test_helper"

class BaliRansackParamNameTest < ActiveSupport::TestCase
  def test_predicate_joins_the_columns_and_appends_the_matcher
    assert_equal("name_or_genre_cont", Bali::RansackParamName.predicate(%i[name genre]))
  end

  def test_predicate_accepts_a_single_column
    assert_equal("name_cont", Bali::RansackParamName.predicate(:name))
  end

  def test_predicate_accepts_strings
    assert_equal("name_or_tenant_name_cont", Bali::RansackParamName.predicate(%w[name tenant_name]))
  end

  def test_predicate_is_nil_without_columns
    assert_nil(Bali::RansackParamName.predicate(nil))
    assert_nil(Bali::RansackParamName.predicate([]))
    assert_nil(Bali::RansackParamName.predicate([ "", nil ]))
  end

  def test_param_wraps_the_predicate_in_the_ransack_scope
    assert_equal("q[name_or_genre_cont]", Bali::RansackParamName.param(%i[name genre]))
  end

  def test_param_is_nil_without_columns
    assert_nil(Bali::RansackParamName.param([]))
  end
end

class BaliSearchConfigTest < ActiveSupport::TestCase
  def test_wrap_accepts_nil
    config = Bali::SearchConfig.wrap(nil)
    assert_not(config.enabled?)
    assert_nil(config.param_name)
  end

  def test_wrap_accepts_a_hash_with_string_keys
    config = Bali::SearchConfig.wrap("fields" => %i[name], "value" => "Iron")
    assert(config.enabled?)
    assert_equal("Iron", config.value)
  end

  def test_wrap_is_idempotent
    config = Bali::SearchConfig.new(fields: %i[name])
    assert_same(config, Bali::SearchConfig.wrap(config))
  end

  def test_derives_the_ransack_param_from_the_columns
    config = Bali::SearchConfig.new(fields: %i[name genre])
    assert_equal("name_or_genre_cont", config.predicate)
    assert_equal("q[name_or_genre_cont]", config.param_name)
  end

  def test_blank_columns_are_dropped
    config = Bali::SearchConfig.new(fields: [ :name, nil, "" ])
    assert_equal([ :name ], config.fields)
  end

  def test_is_disabled_without_columns
    config = Bali::SearchConfig.new(value: "Iron", placeholder: "Search...")
    assert_not(config.enabled?)
  end

  def test_carries_the_presentation_options
    config = Bali::SearchConfig.new(
      fields: %i[name], value: "Iron", placeholder: "Search...",
      label: "Search movies", icon: "search", width: "flex-1"
    )
    assert_equal("Search movies", config.label)
    assert_equal("search", config.icon)
    assert_equal("flex-1", config.width)
  end

  def test_rejects_an_unknown_option
    error = assert_raises(ArgumentError) { Bali::SearchConfig.new(fields: %i[name], placehodler: "typo") }
    assert_includes(error.message, ":placehodler")
  end

  # The v2 shape SimpleFilters took. It has to fail loudly: silently ignoring it
  # renders a search box that submits nothing.
  def test_rejects_the_removed_field_name_option_with_the_replacement
    error = assert_raises(ArgumentError) { Bali::SearchConfig.new(field_name: "q[name_or_email_cont]") }
    assert_includes(error.message, ":field_name")
    assert_includes(error.message, "fields: [:name, :email]")
  end
end
