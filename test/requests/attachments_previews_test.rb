# frozen_string_literal: true

require "test_helper"

# The previews store their sample files on the first visit, which the component tests never
# do: a broken upload or lookup there would 500 with the suite green. Cypress drives the same URLs.
class AttachmentsPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "/lookbook/preview/bali/attachments/default" => "ul.attachments-component > li[id^='attachment_'] img",
    "/lookbook/preview/bali/attachments/with_badge" => "ul.attachments-component > li[id^='attachment_'] .badge",
    "/lookbook/preview/bali/attachments/empty" => "ul.attachments-component > li.attachments-empty"
  }.freeze

  def test_every_attachments_preview_renders_with_its_marker_element
    PREVIEWS.each do |path, marker|
      get path
      assert_response :ok, "#{path} did not render"
      assert_select marker, { minimum: 1 }, "#{path} rendered without #{marker}"
    end
  end
end
