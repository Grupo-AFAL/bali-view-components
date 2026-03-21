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
    assert_selector("button[data-action='feedback-widget#toggle']")
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

  def test_sets_embed_url_data_attribute
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "my-project",
      opina_url: "https://opina.example.com",
      token: "abc123"
    ))

    assert_selector("[data-feedback-widget-embed-url-value='https://opina.example.com/embed/feedback_posts?token=abc123']")
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

    assert_selector("[data-feedback-widget-embed-url-value='https://opina.example.com/embed/feedback_posts?token=abc123']")
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

    assert_selector("button[data-action='feedback-widget#toggle'] .icon-component")
    assert_selector("button[data-action='feedback-widget#close'] .icon-component")
  end

  def test_has_accessible_aria_attributes
    render_inline(Bali::FeedbackWidget::Component.new(
      project_slug: "test",
      opina_url: "https://opina.example.com",
      token: "abc"
    ))

    assert_selector("[role='dialog'][aria-modal='true']")
    assert_selector("[aria-labelledby='feedback-widget-title']")
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
end
