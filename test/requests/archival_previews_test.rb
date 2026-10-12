# frozen_string_literal: true

require "test_helper"

# Component tests render classes, not previews: a preview that 500s stays green everywhere else.
class ArchivalPreviewsTest < ActionDispatch::IntegrationTest
  SCENARIOS = %w[
    archival_form/default archival_form/without_successors
    archival_notice/default archival_notice/minimal archival_notice/reopenable
  ].freeze

  def setup
    Tenant.create!(name: "Studio").movies.create!(name: "Blade Runner 2049", status: 0)
  end

  def test_every_archival_preview_renders
    SCENARIOS.each do |scenario|
      get "/lookbook/preview/bali/#{scenario}"
      assert_response :ok, scenario
    end
  end
end
