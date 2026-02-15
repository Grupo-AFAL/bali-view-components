# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::BlockEditor::Component, type: :component do
  before do
    allow(Bali).to receive(:block_editor_enabled).and_return(true)
  end

  it 'renders block editor component' do
    render_inline(described_class.new)

    expect(page).to have_css 'div.block-editor-component'
  end

  it 'does not render when block_editor_enabled is false' do
    allow(Bali).to receive(:block_editor_enabled).and_return(false)

    render_inline(described_class.new)

    expect(page).not_to have_css 'div.block-editor-component'
  end

  it 'renders editor target container' do
    render_inline(described_class.new)

    expect(page).to have_css '[data-block-editor-target="editor"]'
  end

  it 'renders hidden input when input_name is provided' do
    render_inline(described_class.new(input_name: 'post[content]'))

    expect(page).to have_css 'input[type="hidden"][name="post[content]"]', visible: false
  end

  it 'does not render hidden input when input_name is nil' do
    render_inline(described_class.new)

    expect(page).not_to have_css 'input[type="hidden"][data-block-editor-target="output"]'
  end

  it 'applies editable data value' do
    render_inline(described_class.new(editable: true))

    expect(page).to have_css '[data-block-editor-editable-value="true"]'
  end

  it 'applies non-editable data value' do
    render_inline(described_class.new(editable: false))

    expect(page).to have_css '[data-block-editor-editable-value="false"]'
  end

  it 'does not render hidden input when not editable' do
    render_inline(described_class.new(editable: false, input_name: 'post[content]'))

    expect(page).not_to have_css 'input[type="hidden"]', visible: false
  end

  it 'applies placeholder data value' do
    render_inline(described_class.new(placeholder: 'Write here...'))

    expect(page).to have_css '[data-block-editor-placeholder-value="Write here..."]'
  end

  it 'serializes hash content to JSON' do
    blocks = [{ type: 'paragraph', content: [{ type: 'text', text: 'Hello' }] }]
    render_inline(described_class.new(initial_content: blocks, input_name: 'post[content]'))

    input = page.find('input[type="hidden"]', visible: false)
    expect(input.value).to eq blocks.to_json
  end

  it 'passes string content directly' do
    json_str = '[{"type":"paragraph"}]'
    render_inline(described_class.new(initial_content: json_str, input_name: 'post[content]'))

    input = page.find('input[type="hidden"]', visible: false)
    expect(input.value).to eq json_str
  end

  it 'applies format data value' do
    render_inline(described_class.new(format: :html))

    expect(page).to have_css '[data-block-editor-format-value="html"]'
  end

  it 'applies custom CSS classes' do
    render_inline(described_class.new(class: 'custom-class'))

    expect(page).to have_css 'div.block-editor-component.custom-class'
  end

  it 'sets controller data attribute' do
    render_inline(described_class.new)

    expect(page).to have_css '[data-controller="block-editor"]'
  end

  it 'applies images_url data value' do
    render_inline(described_class.new(images_url: '/uploads'))

    expect(page).to have_css '[data-block-editor-images-url-value="/uploads"]'
  end

  it 'applies html_content data value' do
    render_inline(described_class.new(html_content: '<p>Hello</p>'))

    expect(page).to have_css '[data-block-editor-html-content-value]'
  end
end
