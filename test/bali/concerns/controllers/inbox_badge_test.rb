# frozen_string_literal: true

require "test_helper"

# #1512 — the host's ApplicationController includes the concern (the dummy's does), so the
# layout reads `inbox_badge` and the person's own writes refresh it.
class BaliInboxBadgeConcernTest < ActionDispatch::IntegrationTest
  class ProbesController < ApplicationController
    def show = render(plain: inbox_badge ? inbox_badge.pending.to_s : "none")

    def create = head(:no_content)
  end

  # A page that already counted the projects it lists.
  class WritingProbesController < ApplicationController
    def show
      write_inbox_badge(pending_by_module: { projects: 41 })
      render plain: inbox_badge.pending.to_s
    end
  end

  # bali-auth's helper, private: an admin acting as the demo user.
  class ImpersonatedProbesController < ProbesController
    private

    def impersonating? = true
  end

  class ImpersonatedWritingProbesController < WritingProbesController
    private

    def impersonating? = true
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
        resource :impersonated_probe, only: :show, controller: "bali_inbox_badge_concern_test/impersonated_probes"
        resource :writing_probe, only: :show, controller: "bali_inbox_badge_concern_test/writing_probes"
        resource :impersonated_writing_probe, only: :show,
                                              controller: "bali_inbox_badge_concern_test/impersonated_writing_probes"
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

  # A host may hide rows from an impersonated session, so its number is that session's own: never
  # written to the person's cache, nor read from it.
  def test_while_impersonating_the_badge_is_counted_afresh_and_never_cached
    count = Bali::Inbox::Query.new(User.demo).count.to_s

    draw_probes do
      get "/impersonated_probe"
      assert_equal count, response.body
      refute Rails.cache.exist?(badge_key), "the person's cache, written with the impersonated session's number"

      Rails.cache.write(badge_key, { pending: 99, unread: 0 })
      get "/impersonated_probe"
      assert_equal count, response.body
    end
  end

  def test_a_page_that_counted_a_module_writes_the_badge_and_shows_it
    written = Bali::Inbox::Badge.compute(User.demo, pending_by_module: { projects: 41 }).pending

    draw_probes do
      get "/writing_probe"

      assert_equal written.to_s, response.body
      assert_equal written, Rails.cache.read(badge_key)[:pending]
    end
  end

  def test_while_impersonating_a_page_writes_no_badge
    draw_probes do
      get "/impersonated_writing_probe"

      refute Rails.cache.exist?(badge_key), "the person's cache, written with the impersonated session's number"
    end
  end

  def test_inbox_badge_is_nil_without_an_owner
    draw_probes do
      get "/anonymous_probe"

      assert_equal "none", response.body
    end
  end
end
