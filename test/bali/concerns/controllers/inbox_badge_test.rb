# frozen_string_literal: true

require "test_helper"

# #1512 — the host's ApplicationController includes the concern (the dummy's does), so the
# layout reads `inbox_badge` and the person's own writes refresh it.
class BaliInboxBadgeConcernTest < ActionDispatch::IntegrationTest
  class ProbesController < ApplicationController
    def show = render(plain: inbox_badge ? inbox_badge.pending.to_s : "none")

    def create = head(:no_content)
  end

  class AnonymousProbesController < ApplicationController
    def show = render(plain: inbox_badge ? "badge" : "none")

    private

    def inbox_owner = nil
  end

  def setup
    @cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  def teardown
    Rails.cache = @cache
  end

  def draw_probes
    with_routing do |routes|
      routes.draw do
        resource :probe, only: %i[show create], controller: "bali_inbox_badge_concern_test/probes"
        resource :anonymous_probe, only: :show, controller: "bali_inbox_badge_concern_test/anonymous_probes"
      end
      yield
    end
  end

  def badge_key = "bali/inbox/badge/#{User.demo.to_gid_param}"

  def test_the_layout_reads_the_owners_badge
    draw_probes do
      get "/probe"

      assert_equal Bali::Inbox::Query.new(User.demo).count.to_s, response.body
    end
  end

  def test_a_post_by_the_owner_expires_the_badge
    draw_probes do
      get "/probe"
      assert Rails.cache.exist?(badge_key)

      post "/probe"
      refute Rails.cache.exist?(badge_key)
    end
  end

  def test_a_get_does_not_expire_it
    draw_probes do
      get "/probe"
      get "/probe"

      assert Rails.cache.exist?(badge_key)
    end
  end

  def test_inbox_badge_is_nil_without_an_owner
    draw_probes do
      get "/anonymous_probe"

      assert_equal "none", response.body
    end
  end
end
