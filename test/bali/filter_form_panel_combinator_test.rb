# frozen_string_literal: true

require "test_helper"

# #1345. The panel's combinator (`q[m]`) used to sit at Ransack's root next to the quick search,
# the flat attributes and the simple filters, so an OR between two groups OR-ed all of them:
# "ana" OR genre Action listed every Action movie.
class BaliFilterFormPanelCombinatorTest < ActiveSupport::TestCase
  class PanelFilterForm < Bali::FilterForm
    search_fields :name

    filter_attribute :genre, type: :select, options: [ %w[Drama Drama], %w[Action Action] ]
    filter_attribute :status, type: :select, simple: true, advanced: false,
                     options: [ %w[Draft draft], %w[Done done] ]
    group_by_attribute :genre
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", genre: "Drama", status: :done, studio: studio)
    @anabel = Movie.create!(name: "Anabel", genre: "Comedy", status: :done, studio: studio)
    @bob = Movie.create!(name: "Bob", genre: "Action", status: :draft, studio: studio)
    Rails.cache.clear
  end

  def form(q, **params)
    PanelFilterForm.new(Movie.all, ActionController::Parameters.new(q: q, **params))
  end

  def either_genre(**q)
    { m: "or", g: { "0" => { genre_eq: "Drama" }, "1" => { genre_eq: "Action" } }, **q }
  end

  test "an OR between the panel's groups does not widen the quick search" do
    assert_equal [ @ana ], form(either_genre(name_cont: "ana")).result.to_a
  end

  test "nor a simple filter" do
    assert_equal [ @bob ], form(either_genre(status_eq: "draft")).result.order(:name).to_a
  end

  test "a combinator left without groups combines nothing" do
    assert_empty form({ m: "or", g: { "0" => { unknown_eq: "x" } }, name_cont: "ana", status_eq: "draft" }).result.to_a
  end

  test "the groups still OR among themselves" do
    assert_equal [ @ana, @bob ], form(either_genre).result.order(:name).to_a
  end

  test "group_counts count the narrowed listing" do
    assert_equal({ "Drama" => 1 }, form(either_genre(name_cont: "ana"), group_by: "genre").group_counts)
  end

  # Hosts rewrite `ransack_params[:g]` group by group after `super` (gobierno-corporativo's
  # `rama`, its DomainTreeFiltering), so the panel's groups are nested on the way into Ransack
  # and not in the hash a host overrides.
  test "ransack_params keeps the groups and their combinator where hosts rewrite them" do
    params = form(either_genre(name_cont: "ana")).ransack_params

    assert_equal({ "genre_eq" => "Drama" }, params[:g]["0"])
    assert_equal "or", params[:m]
  end

  test "what is painted and re-emitted does not change" do
    applied = form(either_genre(name_cont: "ana"))

    assert_equal "or", applied.applied_combinator
    assert_equal [ "Drama", "Action" ], applied.filter_groups.map { |group| group[:conditions].sole[:value] }
    assert_includes Bali::Filters::ActiveFilterParams.for_filter_form(applied), [ "q[m]", "or" ]
    assert_equal "or", applied.current_view_payload["combinator"]
  end
end
