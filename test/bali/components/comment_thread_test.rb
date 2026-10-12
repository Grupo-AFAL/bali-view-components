# frozen_string_literal: true

require "test_helper"

class BaliCommentThreadComponentTest < ComponentTestCase
  AT = Time.utc(2026, 10, 11, 15, 30)

  def test_the_list_carries_the_stream_target_id
    render_inline(Bali::CommentThread::Component.new(id: "story_1_comments"))

    assert_selector(".comment-thread-component > ul#story_1_comments")
  end

  def test_comments_render_inside_the_list
    render_inline(Bali::CommentThread::Component.new(id: "comments")) do |thread|
      thread.with_comment(id: "comment_1", author: "Ana García", timestamp: AT) { "First" }
      thread.with_comment(id: "comment_2", author: "Luis Pérez", timestamp: AT) { "Second" }
    end

    assert_selector("ul#comments > li#comment_1", text: "First")
    assert_selector("ul#comments > li#comment_2", text: "Second")
  end

  # The other way in, for a host whose stream renders a partial: the same partial,
  # rendered in the block, has to land where the stream will add the next one.
  def test_the_block_output_renders_inside_the_list
    render_inline(Bali::CommentThread::Component.new(id: "comments")) do
      '<li id="comment_9">From a partial</li>'.html_safe
    end

    assert_selector("ul#comments > li#comment_9", text: "From a partial")
  end

  # The empty state is always in the list and hides itself as soon as it has a
  # sibling, so an append or a remove stream never has to swap it.
  def test_the_empty_state_is_rendered_even_with_comments_and_shows_only_alone
    render_inline(Bali::CommentThread::Component.new(id: "comments")) do |thread|
      thread.with_comment(author: "Ana García", timestamp: AT) { "First" }
    end

    assert_selector("ul#comments > li.hidden.only\\:block", text: "No comments yet.", visible: :all)
  end

  def test_empty_text_replaces_the_default
    render_inline(Bali::CommentThread::Component.new(id: "comments", empty_text: "Be the first"))

    assert_selector("li.only\\:block", text: "Be the first", visible: :all)
  end

  def test_the_form_sits_below_the_list_by_default
    render_inline(Bali::CommentThread::Component.new(id: "comments")) do |thread|
      thread.with_form { "<form></form>".html_safe }
    end

    assert_selector(".comment-thread-component > ul#comments + form")
  end

  def test_form_position_top_puts_the_form_above_the_list
    render_inline(Bali::CommentThread::Component.new(id: "comments", form_position: :top)) do |thread|
      thread.with_form { "<form></form>".html_safe }
    end

    assert_selector(".comment-thread-component > form + ul#comments")
    refute_selector("ul#comments + form")
  end

  def test_an_unknown_form_position_raises_naming_the_accepted_values
    error = assert_raises(ArgumentError) do
      Bali::CommentThread::Component.new(id: "comments", form_position: :side)
    end

    assert_match(/:top, :bottom/, error.message)
  end

  def test_host_options_land_on_the_wrapper_and_the_id_on_the_list
    render_inline(Bali::CommentThread::Component.new(id: "comments", class: "mt-6",
                                                     data: { testid: "thread" }))

    assert_selector(".comment-thread-component.mt-6[data-testid='thread'] > ul#comments")
    assert_selector("#comments", count: 1)
  end
end

class BaliCommentThreadCommentComponentTest < ComponentTestCase
  AT = Time.utc(2026, 10, 11, 15, 30)

  def render_comment(**options, &block)
    render_inline(Bali::CommentThread::Comment::Component.new(
                    author: "Ana García López", timestamp: AT, **options
                  ), &block)
  end

  def test_renders_on_its_own_as_a_list_item_with_the_host_id
    render_comment(id: "comment_1") { "Looks good" }

    assert_selector("li#comment_1.comment-thread-comment", text: "Looks good")
  end

  def test_the_avatar_derives_initials_from_the_author_and_stays_out_of_the_accessibility_tree
    render_comment { "Looks good" }

    assert_selector(".avatar[aria-hidden='true']", text: "AL")
    assert_no_selector(".avatar[role], .avatar[aria-label], .avatar[title]")
    assert_selector("li", text: "Ana García López")
  end

  def test_the_time_is_relative_by_default_with_the_date_in_its_tooltip
    render_comment { "Looks good" }

    assert_selector("time[data-controller='timeago'][datetime='#{AT.to_fs(:iso8601)}']" \
                    "[title='#{I18n.l(AT, format: :short)}']")
  end

  def test_relative_false_shows_the_date_itself
    render_comment(relative: false) { "Looks good" }

    assert_selector("time[datetime='#{AT.to_fs(:iso8601)}']", text: I18n.l(AT, format: :short))
    refute_selector("[data-controller='timeago']")
  end

  def test_actions_render_beside_the_author_not_in_the_body
    render_comment do |comment|
      comment.with_action { '<button type="button">Delete</button>'.html_safe }
      "Looks good"
    end

    assert_selector("div:has(> div > span.font-medium) > div.shrink-0 > button", text: "Delete")
    refute_selector(".break-words button")
  end

  def test_no_actions_wrapper_without_actions
    render_comment { "Looks good" }

    refute_selector("div.shrink-0")
  end
end
