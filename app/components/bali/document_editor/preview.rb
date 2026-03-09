# frozen_string_literal: true

module Bali
  module DocumentEditor
    class Preview < ApplicationViewComponentPreview
      # The full-screen editor overlay.
      # **Note:** This preview renders a fixed overlay that fills the viewport.
      # @param editable toggle
      def default(editable: true)
        sample_content = [
          { "type" => "heading", "props" => { "level" => 1 },
            "content" => [ { "type" => "text", "text" => "Project Overview" } ] },
          { "type" => "paragraph",
            "content" => [ { "type" => "text", "text" => "This is a sample document demonstrating the full-screen editing experience." } ] },
          { "type" => "heading", "props" => { "level" => 2 },
            "content" => [ { "type" => "text", "text" => "Key Objectives" } ] },
          { "type" => "paragraph",
            "content" => [ { "type" => "text", "text" => "The editor supports table of contents, inline comments, version history, and auto-save." } ] }
        ]

        render Bali::DocumentEditor::Component.new(
          title: "Q2 2026 Product Roadmap",
          initial_content: sample_content,
          document_url: "/lookbook",
          close_url: "/lookbook",
          versions_url: "/lookbook",
          editable: editable,
          auto_save: false,
          comments: {
            url: "/block_editor_comments",
            user: { id: "user-1", username: "Demo User" },
            users: [
              { id: "user-1", username: "Demo User" },
              { id: "user-2", username: "Jane Smith" }
            ]
          },
          export: true
        )
      end
    end
  end
end
