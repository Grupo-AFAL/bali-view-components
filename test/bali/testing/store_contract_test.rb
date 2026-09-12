# frozen_string_literal: true

require "test_helper"
require "bali/testing/store_contract"
require "forwardable"
require "delegate"

class BaliTestingStoreContractTest < ActiveSupport::TestCase
  include Bali::Testing::StoreContract

  ALPHA = Class.new(Bali::Widget::ValueBase) do
    def self.key = "alpha"
    value { 1 }
  end

  def owner = @owner ||= User.create!(name: "Contract")

  # BALI'S OWN STORE MUST MEET IT, which is the point: the contract is a
  # paragraph nobody checks unless the default implementation is held to it too.
  def test_balis_own_store_meets_the_contract
    assert_bali_store_contract(
      Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    )
  end

  # A DELEGATING WRAPPER PASSES. Someone wrapping Bali's own Store to add a cache
  # or an audit log is the likeliest replacement of all, and every delegation
  # idiom produces `def choose(...)` — arity -1. An arity assertion refused them.
  def test_a_delegating_wrapper_meets_the_contract
    inner = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    wrapper = Class.new do
      extend Forwardable
      def initialize(inner) = @inner = inner
      def_delegators :@inner, :widgets, :stored_keys, :visible_keys, :customized?,
                     :choose, :arrange, :adopt, :reset
    end.new(inner)

    assert_bali_store_contract wrapper
  end

  # As does a store taking its argument by keyword or with a splat.
  def test_other_one_argument_signatures_meet_the_contract
    inner = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    splatted = Class.new(SimpleDelegator) do
      def choose(*args) = __getobj__.choose(*args)
      def arrange(*args) = __getobj__.arrange(*args)
    end.new(inner)

    assert_bali_store_contract splatted
  end

  # And it FAILS for something that only looks like one — otherwise it is
  # decoration rather than an assertion.
  def test_it_refuses_an_object_missing_part_of_the_contract
    half = Class.new do
      def widgets = []
      def stored_keys = []
      def visible_keys = []
      def customized? = false
      def choose(_widgets) = nil
      def arrange(_layout) = nil
      def reset = nil
      # no `adopt`
    end.new

    error = assert_raises(Minitest::Assertion) { assert_bali_store_contract(half) }

    assert_match(/adopt/, error.message)
  end
end
