# frozen_string_literal: true

require "test_helper"

class BaliFrameComponentTest < ComponentTestCase
  def test_renders_wrapper_and_turbo_frame_with_id
    render_inline(Bali::Frame::Component.new(id: "report"))
    assert_selector("div.frame-loader")
    assert_selector("turbo-frame#report", visible: :all)
  end

  def test_renders_src_and_loading_attributes_when_given
    render_inline(Bali::Frame::Component.new(id: "report", src: "/reports/1", loading: :lazy))
    assert_selector('turbo-frame#report[src="/reports/1"][loading="lazy"]', visible: :all)
  end

  def test_omits_src_and_loading_when_not_given
    render_inline(Bali::Frame::Component.new(id: "report"))
    assert_no_selector("turbo-frame[src]", visible: :all)
    assert_no_selector("turbo-frame[loading]", visible: :all)
  end

  def test_renders_sibling_placeholder_with_spinner
    render_inline(Bali::Frame::Component.new(id: "report"))
    assert_selector("div.frame-loading span.loading.loading-spinner", visible: :all)
  end

  def test_uses_default_i18n_text_in_the_placeholder
    render_inline(Bali::Frame::Component.new(id: "report"))
    assert_selector("div.frame-loading", text: "Loading...", visible: :all)
  end

  def test_uses_custom_text_in_the_placeholder
    render_inline(Bali::Frame::Component.new(id: "report", text: "Consultando…"))
    assert_selector("div.frame-loading", text: "Consultando…", visible: :all)
  end

  def test_block_content_becomes_the_frame_content
    render_inline(Bali::Frame::Component.new(id: "report")) { "contenido cargado" }
    assert_selector("turbo-frame#report", text: "contenido cargado", visible: :all)
  end

  def test_deferred_frame_shows_the_placeholder_as_initial_content
    render_inline(Bali::Frame::Component.new(id: "report", src: "/reports/1", loading: :lazy))
    assert_selector("turbo-frame#report span.loading.loading-spinner", visible: :all)
  end

  def test_custom_loading_slot_replaces_the_default_placeholder
    render_inline(Bali::Frame::Component.new(id: "report")) do |frame|
      frame.with_loading { "skeleton a medida" }
    end
    assert_selector("div.frame-loading", text: "skeleton a medida", visible: :all)
    assert_no_selector("div.frame-loading span.loading", visible: :all)
  end

  def test_options_passthrough_accepts_custom_classes_on_wrapper
    render_inline(Bali::Frame::Component.new(id: "report", class: "my-frame"))
    assert_selector("div.frame-loader.my-frame")
  end

  def test_options_passthrough_accepts_data_attributes_on_wrapper
    render_inline(Bali::Frame::Component.new(id: "report", data: { testid: "frame" }))
    assert_selector('div.frame-loader[data-testid="frame"]')
  end
end
