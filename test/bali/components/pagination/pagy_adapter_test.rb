# frozen_string_literal: true

require "test_helper"

# The adapter is the only place in Bali that touches Pagy, so these are the tests that have
# to fail when Pagy changes under us. They pin the two things the gem does not promise —
# `series` being protected and the request living in an ivar — plus the URL contract Bali
# builds on top of them.
class BaliPaginationPagyAdapterTest < ActiveSupport::TestCase
  def setup
    @pagy = Pagy::Offset.new(count: 100, page: 3, limit: 10)
  end

  def adapter(pagy = @pagy, **)
    Bali::Pagination::PagyAdapter.new(pagy, **)
  end

  def linkable_pagy(params: {}, path: "/admin/movies", **options)
    request = Pagy::Request.new(
      request: { base_url: "http://example.com", path: path, params: params, cookie: nil }
    )
    Pagy::Offset.new(count: 100, page: 3, limit: 10, request: request, **options)
  end

  # --- numbers ------------------------------------------------------------------------

  def test_exposes_the_page_numbers_the_controls_need
    a = adapter
    assert_equal 10, a.pages
    assert_equal 3, a.current_page
    assert_equal 2, a.previous_page
    assert_equal 4, a.next_page
  end

  def test_exposes_the_counts_the_summary_needs
    a = adapter
    assert_equal 100, a.count
    assert_equal 21, a.from
    assert_equal 30, a.to
  end

  def test_previous_and_next_are_nil_at_the_edges
    assert_nil adapter(Pagy::Offset.new(count: 100, page: 1, limit: 10)).previous_page
    assert_nil adapter(Pagy::Offset.new(count: 100, page: 10, limit: 10)).next_page
  end

  def test_navigable_only_with_more_than_one_page
    assert_predicate adapter, :navigable?
    refute_predicate adapter(Pagy::Offset.new(count: 5, page: 1, limit: 10)), :navigable?
  end

  # --- summary ------------------------------------------------------------------------

  def test_summarizable_is_false_without_results
    refute_predicate adapter(Pagy::Offset.new(count: 0, page: 1, limit: 10)), :summarizable?
  end

  def test_summarizable_with_results
    assert_predicate adapter, :summarizable?
  end

  # Countless pagination leaves `count` nil on purpose. The old code interpolated the nil into
  # "Showing 1-10 of  items"; asking for `.positive?` on it would raise instead.
  def test_summarizable_is_false_without_a_count
    countless = Pagy::Offset::Countless.new(page: 1, limit: 10, last: 3)
    assert_nil countless.count
    refute_predicate adapter(countless), :summarizable?
  end

  def test_summary_uses_the_default_item_name
    assert_equal "Showing 21-30 of 100 items", adapter.summary
  end

  def test_summary_uses_a_custom_item_name
    assert_equal "Showing 21-30 of 100 movies", adapter.summary("movies")
  end

  def test_summary_falls_back_to_the_default_on_a_blank_item_name
    assert_equal "Showing 21-30 of 100 items", adapter.summary("")
  end

  def test_summary_is_translated
    I18n.with_locale(:es) do
      assert_equal "Mostrando 21-30 de 100 elementos", adapter.summary
    end
  end

  def test_summary_pluralizes_the_default_item_name_by_count
    pagy = Pagy::Offset.new(count: 1, page: 1, limit: 10)
    assert_equal "Showing 1-1 of 1 item", adapter(pagy).summary
  end

  def test_summary_picks_one_or_other_from_a_hash_item_name
    one = Pagy::Offset.new(count: 1, page: 1, limit: 10)
    assert_equal "Showing 1-1 of 1 movie", adapter(one).summary(one: "movie", other: "movies")
    assert_equal "Showing 21-30 of 100 movies", adapter.summary(one: "movie", other: "movies")
  end

  def test_summary_resolves_a_symbol_item_name_through_i18n_with_count
    I18n.backend.store_translations(:en, movies_for_test: { one: "movie", other: "movies" })
    one = Pagy::Offset.new(count: 1, page: 1, limit: 10)
    assert_equal "Showing 1-1 of 1 movie", adapter(one).summary(:movies_for_test)
  end

  # --- series -------------------------------------------------------------------------

  # Pagy keeps `series` protected; this is the shape the template's `case` depends on.
  def test_series_marks_the_current_page_with_a_string
    assert_equal "3", adapter.series.find { |item| item.is_a?(String) }
  end

  def test_series_uses_gap_symbols_for_elisions
    series = adapter(Pagy::Offset.new(count: 500, page: 25, limit: 10)).series
    assert_includes series, :gap
    assert_equal 1, series.first
    assert_equal 50, series.last
  end

  def test_series_returns_every_page_when_they_fit
    assert_equal [ 1, "2", 3 ], adapter(Pagy::Offset.new(count: 25, page: 2, limit: 10)).series
  end

  # --- urls ---------------------------------------------------------------------------

  def test_a_bare_pagy_is_not_linkable
    refute_predicate adapter, :linkable?
  end

  def test_a_pagy_built_from_a_request_is_linkable
    assert_predicate adapter(linkable_pagy), :linkable?
  end

  def test_a_linkable_pagy_builds_its_own_urls_and_keeps_the_query_string
    a = adapter(linkable_pagy(params: { "q" => "batman" }))
    assert_equal "/admin/movies?q=batman&page=5", a.page_url(5)
  end

  def test_a_bare_pagy_falls_back_to_a_relative_url
    assert_equal "?page=5", adapter.page_url(5)
  end

  def test_base_url_is_used_when_the_pagy_cannot_build_urls
    assert_equal "/movies?page=5", adapter(base_url: "/movies").page_url(5)
  end

  def test_base_url_keeps_the_query_string_it_carries
    assert_equal "/movies?q=batman&page=5",
      adapter(base_url: "/movies?q=batman&page=1").page_url(5)
  end

  # #654: `url:` used to be silently dropped whenever the Pagy carried a request, which is
  # always with the `pagy()` helper. Passing it now means it wins.
  def test_base_url_wins_over_a_linkable_pagy
    a = adapter(linkable_pagy(params: { "q" => "batman" }), base_url: "/elsewhere")
    assert_equal "/elsewhere?page=5", a.page_url(5)
  end

  def test_honours_a_custom_page_key
    a = adapter(Pagy::Offset.new(count: 100, page: 3, limit: 10, page_key: "p"))
    assert_equal "?p=5", a.page_url(5)
  end

  # Countless does not put the page number in the URL: it puts `"5+4"`, the page plus the last
  # page it knows about, wrapped in a `Pagy::EscapedValue` so the `+` survives. Building the
  # query with Rack escaped it to `5%2B4` and the link came back missing the half Pagy needs.
  # The contract is that a hand-composed URL is the SAME one Pagy builds from its request.
  def test_a_composed_url_matches_pagy_for_countless_pagination
    request = Pagy::Request.new(
      request: { base_url: "http://example.com", path: "/movies", params: { "q" => "b" }, cookie: nil }
    )
    # No `records` call: it would recompute `last` from whatever the fixtures happen to hold,
    # and the encoding under test is the same either way.
    countless = Pagy::Offset::Countless.new(page: 2, limit: 10, last: 4, request: request)

    assert_equal "/movies?q=b&page=5+4", countless.page_url(5)
    assert_equal countless.page_url(5), adapter(countless, base_url: "/movies?q=b").page_url(5)
  end

  # --- fragment -----------------------------------------------------------------------

  def test_fragment_is_appended_to_a_composed_url
    assert_equal "/movies?page=5#results",
      adapter(base_url: "/movies", fragment: "#results").page_url(5)
  end

  def test_fragment_gets_its_hash_prepended_when_missing
    assert_equal "/movies?page=5#results",
      adapter(base_url: "/movies", fragment: "results").page_url(5)
  end

  def test_fragment_reaches_a_linkable_pagy
    a = adapter(linkable_pagy, fragment: "#results")
    assert_equal "/admin/movies?page=5#results", a.page_url(5)
  end
end
