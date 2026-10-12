# frozen_string_literal: true

module Bali
  module CommentThread
    class Preview < ApplicationViewComponentPreview
      # @label Thread
      # Comments with their actions, and the form that adds to them.
      #
      # The list's `id:` is what the host's streams target. The empty state is
      # already in the list, hidden while it has company, so adding the first
      # comment or deleting the last one is a plain `append`, `prepend` or `remove`:
      #
      # ```ruby
      # turbo_stream.prepend "comments", partial: "comments/comment", locals: { comment: }
      # turbo_stream.remove dom_id(comment)
      # ```
      #
      # @param form_position select [bottom, top]
      # @param relative toggle "Relative time, with the date in its tooltip"
      def default(form_position: :bottom, relative: true)
        render_with_template(
          template: "bali/comment_thread/previews/default",
          locals: { form_position: form_position.to_sym, relative: relative }
        )
      end

      # @label Empty
      # No comments yet: the empty state is the list's only item, so it shows.
      #
      # @param empty_text text "Leave blank for the text from the locale files"
      def empty(empty_text: "")
        render_with_template(
          template: "bali/comment_thread/previews/empty",
          locals: { empty_text: empty_text }
        )
      end
    end
  end
end
