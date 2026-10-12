# frozen_string_literal: true

require "test_helper"

# The component tests render classes, not previews: the nested
# `Bali::CommentThread::Comment` constant resolving under a namespace Zeitwerk
# reloads, and the templates `render_with_template` looks up, could 500 with the
# suite green. Cypress drives the same two URLs.
class CommentThreadPreviewsTest < ActionDispatch::IntegrationTest
  PREVIEWS = {
    "/lookbook/preview/bali/comment_thread/default" => "ul#comments > li.comment-thread-comment",
    "/lookbook/preview/bali/comment_thread/empty" => "ul#comments > li.only\\:block"
  }.freeze

  def test_every_comment_thread_preview_renders_with_its_marker_element
    PREVIEWS.each do |path, marker|
      get path
      assert_response :ok, "#{path} did not render"
      assert_select marker, { minimum: 1 }, "#{path} rendered without #{marker}"
    end
  end
end
