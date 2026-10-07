# frozen_string_literal: true

require "test_helper"

# #1347. A saved view's payload comes back from a jsonb, or from whatever store the host wrote,
# so any JSON can arrive in it. Each of these took the listing down with a 500 every time the
# view was opened; a part that is not a hash now applies nothing.
class BaliFilterFormSavedViewPayloadTest < ActiveSupport::TestCase
  class ViewFilterForm < Bali::FilterForm
    search_fields :name

    filter_attribute :genre, type: :select, options: [ %w[Drama Drama], %w[Action Action] ]
    filter_attribute :status, type: :select, simple: true, advanced: false, options: [ %w[Draft draft] ]

    attribute :name_cont
  end

  View = Struct.new(:id, :name, :payload)

  Store = Struct.new(:view) do
    def list = [ view ]
    def find(_id) = view
  end

  MALFORMED = [
    { "simple_filters" => "x" },
    { "simple_filters" => [ "x" ] },
    { "groupings" => "x" },
    { "groupings" => [ "x" ] },
    { "groupings" => { "0" => "x" } },
    { "attributes" => "x" },
    { "attributes" => [ "x" ] },
    "x",
    [ "x" ]
  ].freeze

  def setup
    studio = Tenant.create!(name: "Acme")
    @ana = Movie.create!(name: "Ana", genre: "Drama", status: :draft, studio: studio)
    @bob = Movie.create!(name: "Bob", genre: "Action", status: :done, studio: studio)
  end

  def open(payload)
    ViewFilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"),
                       saved_views_store: Store.new(View.new(1, "View", payload)))
  end

  test "a payload, or a part of it, that is not a hash opens the listing unfiltered" do
    MALFORMED.each do |payload|
      assert_equal 2, open(payload).result.count, payload.inspect
    end
  end

  test "the rest of the payload still applies" do
    applied = open({ "simple_filters" => "x", "attributes" => [ "x" ], "search_value" => "Ana",
                     "groupings" => { "0" => "x", "1" => { "genre_eq" => "Drama" } } })

    assert_equal [ @ana ], applied.result.to_a
    assert_equal [ "genre" ], applied.filter_groups.map { |group| group[:conditions].sole[:attribute] }
  end

  # The shape Ransack accepts and a URL already gets normalized from (`q[g][]`).
  test "groupings as a list of groups read as the URL's" do
    applied = open({ "groupings" => [ { "genre_eq" => "Action" } ] })

    assert_equal [ "Action" ], applied.filter_groups.map { |group| group[:conditions].sole[:value] }
    assert_equal [ @bob ], applied.result.to_a
  end
end
