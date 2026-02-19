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

  it 'applies upload_url data value when explicitly set' do
    render_inline(described_class.new(upload_url: '/uploads'))

    expect(page).to have_css '[data-block-editor-upload-url-value="/uploads"]'
  end

  it 'applies html_content data value' do
    render_inline(described_class.new(html_content: '<p>Hello</p>'))

    expect(page).to have_css '[data-block-editor-html-content-value]'
  end

  context 'with auto upload_url' do
    it 'resolves from Bali.block_editor_upload_url config' do
      allow(Bali).to receive(:block_editor_upload_url).and_return('/bali/block_editor/uploads')

      render_inline(described_class.new)

      expect(page).to have_css '[data-block-editor-upload-url-value="/bali/block_editor/uploads"]'
    end

    it 'does not set upload_url when not editable' do
      allow(Bali).to receive(:block_editor_upload_url).and_return('/bali/block_editor/uploads')

      render_inline(described_class.new(editable: false))

      expect(page).not_to have_css '[data-block-editor-upload-url-value]'
    end

    it 'does not set upload_url when upload_url is nil' do
      render_inline(described_class.new(upload_url: nil))

      expect(page).not_to have_css '[data-block-editor-upload-url-value]'
    end
  end

  context 'with table_of_contents' do
    it 'sets table_of_contents value to false by default' do
      render_inline(described_class.new)

      expect(page).to have_css '[data-block-editor-table-of-contents-value="false"]'
    end

    it 'sets table_of_contents value to true when enabled' do
      render_inline(described_class.new(table_of_contents: true))

      expect(page).to have_css '[data-block-editor-table-of-contents-value="true"]'
    end
  end

  context 'with comments' do
    it 'sets comments value to false by default' do
      render_inline(described_class.new)

      expect(page).to have_css '[data-block-editor-comments-value="false"]'
    end

    it 'sets comments value to true when enabled' do
      render_inline(described_class.new(comments: true, comments_user: { id: '1', username: 'Alice' }))

      expect(page).to have_css '[data-block-editor-comments-value="true"]'
    end

    it 'serializes comments_user as JSON' do
      user = { id: '1', username: 'Alice', avatar_url: '' }
      render_inline(described_class.new(comments: true, comments_user: user))

      expect(page).to have_css '[data-block-editor-comments-user-value]'
      el = page.find('[data-block-editor-comments-user-value]')
      parsed = JSON.parse(el[:'data-block-editor-comments-user-value'])
      expect(parsed['id']).to eq '1'
      expect(parsed['username']).to eq 'Alice'
    end

    it 'serializes comments_users as JSON array' do
      users = [
        { id: '1', username: 'Alice' },
        { id: '2', username: 'Bob' }
      ]
      render_inline(described_class.new(comments: true, comments_user: { id: '1', username: 'Alice' }, comments_users: users))

      el = page.find('[data-block-editor-comments-users-value]')
      parsed = JSON.parse(el[:'data-block-editor-comments-users-value'])
      expect(parsed).to be_an(Array)
      expect(parsed.length).to eq 2
      expect(parsed.first['username']).to eq 'Alice'
    end

    it 'applies comments_users_url data value' do
      render_inline(described_class.new(comments: true, comments_user: { id: '1', username: 'Alice' }, comments_users_url: '/api/users'))

      expect(page).to have_css '[data-block-editor-comments-users-url-value="/api/users"]'
    end

    it 'applies comments_url data value for REST persistence' do
      render_inline(described_class.new(comments: true, comments_user: { id: '1', username: 'Alice' }, comments_url: '/block_editor_comments'))

      expect(page).to have_css '[data-block-editor-comments-url-value="/block_editor_comments"]'
    end

    it 'defaults comments_url to empty string' do
      render_inline(described_class.new(comments: true, comments_user: { id: '1', username: 'Alice' }))

      expect(page).to have_css '[data-block-editor-comments-url-value=""]'
    end
  end

  context 'export functionality' do
    it 'does not render export buttons by default' do
      render_inline(described_class.new)

      expect(page).not_to have_css '[data-action*="exportPdf"]'
      expect(page).not_to have_css '[data-action*="exportDocx"]'
    end

    it 'renders both export buttons when export: true' do
      render_inline(described_class.new(export: true))

      expect(page).to have_css 'button[data-action="block-editor#exportPdf"]'
      expect(page).to have_css 'button[data-action="block-editor#exportDocx"]'
      expect(page).to have_text 'Export PDF'
      expect(page).to have_text 'Export DOCX'
    end

    it 'renders only PDF button when export: [:pdf]' do
      render_inline(described_class.new(export: [:pdf]))

      expect(page).to have_css 'button[data-action="block-editor#exportPdf"]'
      expect(page).not_to have_css '[data-action*="exportDocx"]'
    end

    it 'renders only DOCX button when export: [:docx]' do
      render_inline(described_class.new(export: [:docx]))

      expect(page).not_to have_css '[data-action*="exportPdf"]'
      expect(page).to have_css 'button[data-action="block-editor#exportDocx"]'
    end

    it 'applies export_filename data value' do
      render_inline(described_class.new(export_filename: 'my-report'))

      expect(page).to have_css '[data-block-editor-export-filename-value="my-report"]'
    end

    it 'defaults export_filename to document' do
      render_inline(described_class.new)

      expect(page).to have_css '[data-block-editor-export-filename-value="document"]'
    end
  end
end
