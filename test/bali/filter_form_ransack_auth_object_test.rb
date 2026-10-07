# frozen_string_literal: true

require "test_helper"

# #1348. `ransackable_attributes(auth_object)` is how Ransack narrows what can be searched by
# who is searching, and the form had nowhere to put one: identity overrode `ransack_search`
# whole, and the other searches the form builds — the grouping's validation, the whole-day
# probe — kept searching without it.
class BaliFilterFormRansackAuthObjectTest < ActiveSupport::TestCase
  class CatalogMovie < ActiveRecord::Base
    self.table_name = "movies"

    ransacker :budget_band do |parent|
      Arel::Nodes::Case.new.when(parent.table[:budget].gteq(5_000_000)).then("mid").else("indie")
    end

    def self.ransackable_attributes(auth_object = nil)
      auth_object == :catalog ? %w[name genre created_at budget_band] : %w[name]
    end

    def self.ransackable_associations(_auth_object = nil) = []
  end

  class CatalogFilterForm < Bali::FilterForm
    filter_attribute :genre, type: :select
    filter_attribute :created_at, type: :date

    attribute :genre_eq

    def ransack_auth_object = :catalog
  end

  class GroupedCatalogFilterForm < CatalogFilterForm
    group_by_attribute :budget_band, value: ->(_movie) { "indie" }
  end

  def setup
    studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", genre: "Drama", budget: 100, created_at: Time.zone.parse("2026-01-10 15:00"), studio: studio)
    @bob = Movie.create!(name: "Bob", genre: "Action", studio: studio)
  end

  def params(q, **rest)
    ActionController::Parameters.new(q: q, **rest)
  end

  test "there is none by default" do
    form = Bali::FilterForm.new(CatalogMovie.all, params({ g: { "0" => { genre_eq: "Drama" } } }))

    assert_nil form.ransack_auth_object
    assert_equal 2, form.result.count
  end

  test "the form's search gets it" do
    form = CatalogFilterForm.new(CatalogMovie.all, params({ genre_eq: "Drama" }))

    assert_equal :catalog, form.ransack_search.context.auth_object
    assert_equal [ @ana.id ], form.result.ids
  end

  test "a grouping the auth object opens is a grouping" do
    form = GroupedCatalogFilterForm.new(CatalogMovie.all, params({}, group_by: "budget_band"))

    assert_equal({ "indie" => 2 }, form.group_counts)
  end

  test "an advanced condition on a day reads the whole day through it" do
    form = CatalogFilterForm.new(CatalogMovie.all, params({ g: { "0" => { created_at_eq: "2026-01-10" } } }))

    assert_equal [ @ana.id ], form.result.ids
  end
end
