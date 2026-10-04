# frozen_string_literal: true

require "test_helper"

class BaliFeedbackWidgetComponentTest < ComponentTestCase
  def test_renders_with_token
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test-project",
      opina_url: "https://opina.example.com",
      token: "pre-built-token"
    ))

    assert_selector("div.feedback-widget")
    assert_selector("button[data-action='feedback-widget#open']")
  end

  # The widget's panel is opened by its own button, which names it by id. While it also
  # answered broadcasts, it opened on every ordinary `drawer#open` trigger on the page too —
  # and since only the drawer holding the submitted form gets closed, the widget's stayed
  # `showModal()`-ed with the whole document inert behind it (#854).
  def test_its_drawer_only_opens_when_something_names_it
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test-project",
      opina_url: "https://opina.example.com",
      token: "pre-built-token"
    ))

    assert_selector("dialog.drawer-component[data-drawer-shared-value='false']")
  end

  def test_renders_with_secret
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test-project",
      opina_url: "https://opina.example.com",
      secret: "test-secret",
      user_id: 1,
      email: "user@example.com"
    ))

    assert_selector("div.feedback-widget")
  end

  def test_raises_without_token_or_secret
    assert_raises(ArgumentError) do
      render_inline(Bali::FeedbackWidget::Component.new(
        project_slug: "test-project",
        opina_url: "https://opina.example.com"
      ))
    end
  end

  # The credential is NOT in the URL. A URL is written to the server's access
  # log, offered in the `Referer` of anything the embed loads, and kept in
  # browser history; the token travels by `postMessage` instead.
  def test_embed_url_carries_no_token
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "my-project",
      opina_url: "https://opina.example.com",
      token: "abc123"
    ))

    assert_selector("[data-feedback-widget-embed-url-value='https://opina.example.com/embed/feedback_posts']")
    assert_selector("[data-feedback-widget-token-value='abc123']")
    assert_no_selector("[data-feedback-widget-embed-url-value*='token']")
  end

  # `postMessage` is addressed to this and never to `*`, so a wildcard cannot
  # hand the token to whatever document happens to be in the frame.
  def test_sets_embed_origin_for_the_token_message
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "my-project",
      opina_url: "https://opina.example.com/feedback",
      token: "abc123"
    ))

    assert_selector("[data-feedback-widget-embed-origin-value='https://opina.example.com']")
  end

  def test_keeps_a_non_default_port_in_the_embed_origin
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "my-project",
      opina_url: "http://localhost:3001",
      token: "abc123"
    ))

    assert_selector("[data-feedback-widget-embed-origin-value='http://localhost:3001']")
  end

  def test_sets_badge_url_data_attribute
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "my-project",
      opina_url: "https://opina.example.com",
      token: "abc123"
    ))

    assert_selector("[data-feedback-widget-badge-url-value='https://opina.example.com/api/v1/projects/my-project/badge']")
  end

  def test_strips_trailing_slash_from_opina_url
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "my-project",
      opina_url: "https://opina.example.com/",
      token: "abc123"
    ))

    assert_selector("[data-feedback-widget-embed-url-value='https://opina.example.com/embed/feedback_posts']")
  end

  def test_sets_badge_interval
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test",
      opina_url: "https://opina.example.com",
      token: "abc",
      badge_interval: 60_000
    ))

    assert_selector("[data-feedback-widget-interval-value='60000']")
  end

  def test_uses_icon_components
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test",
      opina_url: "https://opina.example.com",
      token: "abc"
    ))

    assert_selector("button[data-action='feedback-widget#open'] .icon-component")
    # The panel's ✕ belongs to the composed Bali::Drawer, not to this component.
    assert_selector("button[data-action='drawer#close'] .icon-component")
  end

  def test_has_accessible_aria_attributes
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test",
      opina_url: "https://opina.example.com",
      token: "abc"
    ))

    # The panel is a Bali::Drawer, so it is a native <dialog> whose accessible
    # name comes from the drawer title. The id is unchanged from the
    # hand-written panel this replaced.
    assert_selector("dialog.drawer-component#feedback-widget[aria-labelledby='feedback-widget-title']")
    assert_selector("#feedback-widget-title")
  end

  def test_default_title
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test",
      opina_url: "https://opina.example.com",
      token: "abc"
    ))

    assert_selector("#feedback-widget-title", text: "Feedback")
  end

  def test_custom_title
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test",
      opina_url: "https://opina.example.com",
      token: "abc",
      title: "Send us feedback"
    ))

    assert_selector("#feedback-widget-title", text: "Send us feedback")
  end

  def test_the_trigger_floats_unless_told_otherwise
    render_inline(widget)

    assert_selector("button.fixed[data-action='feedback-widget#open']")
  end

  def test_the_topbar_triggers_render_in_place_at_the_height_of_the_topbar_actions
    %i[icon labeled].each do |trigger|
      render_inline(widget(trigger: trigger))

      assert_selector("button.btn-sm[data-action='feedback-widget#open']")
      assert_no_selector("button.fixed")
    end
  end

  def test_an_unknown_trigger_raises_naming_the_accepted_values
    error = assert_raises(ArgumentError) { widget(trigger: :topbar) }

    assert_match(/unknown trigger :topbar\. Valid: :floating, :icon, :labeled/, error.message)
  end

  # What a caller who knows `Bali::Command::Component.new(trigger: false)` writes.
  def test_a_trigger_that_is_not_a_name_raises_the_same_way
    error = assert_raises(ArgumentError) { widget(trigger: false) }

    assert_match(/unknown trigger false\. Valid: :floating, :icon, :labeled/, error.message)
  end

  def test_the_icon_triggers_are_named_by_their_aria_label
    %i[floating icon].each do |trigger|
      render_inline(widget(trigger: trigger))

      assert_selector("button[aria-label='Open feedback']")
    end
  end

  # Named by its text, so the name holds the words on screen even when the host's
  # `title:` is not the one `open_label` was written around.
  def test_the_labeled_trigger_is_named_by_the_title_it_shows
    render_inline(widget(trigger: :labeled, title: "Send us feedback"))

    assert_selector("button:not([aria-label])", text: "Send us feedback")
  end

  # The count in the badge is decoration; the description is what is read out, and it
  # sits outside the button so the labeled trigger does not also take it into its name.
  def test_every_trigger_is_described_by_the_unread_count_outside_it
    Bali::FeedbackWidget::Component::TRIGGERS.each do |trigger|
      render_inline(widget(trigger: trigger))

      assert_selector("button[aria-describedby='feedback-widget-unread'] [data-feedback-widget-target='badge'][aria-hidden='true']")
      assert_selector(".feedback-widget > #feedback-widget-unread[hidden]", visible: :all)
    end
  end

  # The controller's `showUnread` replaces the `%{count}` left in it.
  def test_passes_the_unread_text_with_its_count_placeholder
    render_inline(widget)

    assert_selector("[data-feedback-widget-unread-label-value='%{count} unread']")
  end

  def test_sets_the_url_that_marks_the_badge_read
    render_inline(widget(project_slug: "my-project"))

    assert_selector("[data-feedback-widget-read-url-value='https://opina.example.com/api/v1/projects/my-project/badge/read']")
  end

  def test_threads_user_name_into_generated_token
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test-project",
      opina_url: "https://opina.example.com",
      secret: "test-secret",
      user_id: 1,
      email: "user@example.com",
      user_name: "Ana López"
    ))

    token = page.find("[data-feedback-widget-token-value]")[:"data-feedback-widget-token-value"]
    payload = JSON.parse(Base64.urlsafe_decode64(token.split(".")[1]))

    assert_equal "Ana López", payload["name"]
  end

  private

  def widget(**options)
    Bali::FeedbackWidget::Component.new(
      **{ project_slug: "test", opina_url: "https://opina.example.com", token: "abc" }.merge(options)
    )
  end
end
