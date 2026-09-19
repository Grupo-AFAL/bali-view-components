# frozen_string_literal: true

require "test_helper"

class MalformedQFilterForm < Bali::FilterForm
  attribute :name_i_cont, :string
end

class MalformedQSimpleFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, simple: true, advanced: false,
                   options: [ %w[Action Action], %w[Comedy Comedy] ]
  attribute :genre_eq
end

# `?q=loquesea` — a scalar where the listing expects a hash. Typing it into the address bar needs
# no session and no knowledge of the app, so a listing that falls over on it is a 500 any visitor
# can fire.
class FilterFormMalformedQTest < ActiveSupport::TestCase
  test "a scalar q does not take the form down" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_nil form.name_i_cont
  end

  test "an array q does not take the form down either" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: [ "loquesea" ]))

    assert_nil form.name_i_cont
  end

  test "a junk q comes out unfiltered, not empty" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_equal Movie.count, form.result.count
  end

  # With simple filters on there is a SECOND `permit` over the same value, running at build time: if
  # this form builds and does not filter, both of them held.
  test "a scalar q does not take down the simple filters second permit either" do
    form = MalformedQSimpleFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_equal Movie.count, form.result.count
  end

  # `q[g]` and `q[m]` are read by the advanced panel, and `q[s]` by the sorting: all three come out
  # of the same value, so a scalar reaches all of them.
  test "a scalar q takes down neither groupings, combinator nor sorting" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: "loquesea"))

    assert_nothing_raised { form.result.to_sql }
  end

  # The healthy case, so the fix does not eat the normal path.
  test "a hash q keeps filtering" do
    form = MalformedQFilterForm.new(Movie.all, ActionController::Parameters.new(q: { name_i_cont: "Iron" }))

    assert_equal "Iron", form.name_i_cont
  end

  # A host can build the form outside a request —a job, an export— and there `params` is a bare Hash,
  # not ActionController::Parameters.
  test "a bare hash keeps filtering" do
    form = MalformedQFilterForm.new(Movie.all, { q: { name_i_cont: "Iron" } })

    assert_equal "Iron", form.name_i_cont
  end

  test "no params at all does not blow up" do
    form = MalformedQFilterForm.new(Movie.all)

    assert_nil form.name_i_cont
  end
end
