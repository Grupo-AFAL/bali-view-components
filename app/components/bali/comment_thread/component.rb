# frozen_string_literal: true

module Bali
  module CommentThread
    # A list of comments and the form that adds to it, above or below.
    #
    # The list carries an empty state that shows only while it is the list's sole
    # child, so the host adds and drops comments with plain `append`, `prepend` and
    # `remove` streams against `id:`, and never replaces the list to swap that state
    # in or out.
    #
    #   <%= render Bali::CommentThread::Component.new(id: dom_id(story, :comments_list)) do |thread| %>
    #     <% story.comments.each do |comment| %>
    #       <% thread.with_comment(id: dom_id(comment), author: comment.user.name,
    #                              timestamp: comment.created_at) do |c| %>
    #         <%= markdown(comment.body) %>
    #         <% c.with_action { button_to 'Delete', comment, method: :delete } %>
    #       <% end %>
    #     <% end %>
    #     <% thread.with_form { render 'comments/form', story: } %>
    #   <% end %>
    #
    # A host whose stream renders a partial renders that same partial in the block
    # instead of `with_comment`: whatever the block outputs lands in the list.
    #
    #   turbo_stream.prepend dom_id(story, :comments_list), partial: 'comments/comment',
    #                                                       locals: { comment: }
    class Component < ApplicationViewComponent
      FORM_POSITIONS = %i[top bottom].freeze

      renders_many :comments, Bali::CommentThread::Comment::Component
      renders_one :form

      # @param id [String] DOM id of the `<ul>`: the target of the host's `append`,
      #   `prepend` and `remove` streams.
      # @param empty_text [String, nil] What the list says while it holds no comment
      #   (default: from the locale files).
      # @param form_position [Symbol] `:bottom` or `:top`: where the `form` slot
      #   sits, relative to the list.
      def initialize(id:, empty_text: nil, form_position: :bottom, **options)
        @id = id
        @empty_text = empty_text.presence || I18n.t("bali_view.comment_thread.empty")
        @form_position = form_position&.to_sym
        unless FORM_POSITIONS.include?(@form_position)
          raise ArgumentError,
                "Bali::CommentThread form_position: #{form_position.inspect} is not one of " \
                "#{FORM_POSITIONS.map(&:inspect).join(', ')}"
        end

        @options = prepend_class_name(options, "comment-thread-component")
      end

      private

      attr_reader :id, :empty_text, :form_position, :options

      def form_at?(position)
        form? && form_position == position
      end
    end
  end
end
