# frozen_string_literal: true

module Bali
  module CommentThread
    module Comment
      # One comment: avatar, author, time, the host's body and its actions.
      #
      # Renders on its own, which is what a stream adding a comment to a
      # `Bali::CommentThread` sends:
      #
      #   turbo_stream.append dom_id(story, :comments_list) do
      #     render Bali::CommentThread::Comment::Component.new(
      #       id: dom_id(comment), author: comment.user.name, timestamp: comment.created_at
      #     ) { comment.body }
      #   end
      #
      # The body is the block, rendered as given: Markdown or plain text, and
      # whatever sanitising it needs, are the host's.
      class Component < ApplicationViewComponent
        TIME_CLASSES = "text-xs text-base-content/70"

        renders_many :actions

        # @param author [String] The commenter's name; the avatar derives its
        #   initials and colour from it.
        # @param timestamp [Time] When the comment was written.
        # @param relative [Boolean] `true` shows the distance ("5 minutes ago"),
        #   with the date in its tooltip; `false` shows the date itself.
        def initialize(author:, timestamp:, relative: true, **options)
          @author = author
          @timestamp = timestamp
          @relative = relative
          @options = prepend_class_name(options, "comment-thread-comment")
        end

        private

        attr_reader :author, :timestamp, :relative, :options

        def absolute_time
          I18n.l(timestamp, format: :short)
        end

        def time
          if relative
            render Bali::Timeago::Component.new(
              timestamp, add_suffix: true, include_seconds: false,
                         title: absolute_time, class: TIME_CLASSES
            )
          else
            tag.time(absolute_time, datetime: timestamp.to_fs(:iso8601), class: TIME_CLASSES)
          end
        end
      end
    end
  end
end
