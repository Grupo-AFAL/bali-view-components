# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Lexxy::Component, type: :component do
  describe 'basic rendering' do
    it 'renders a wrapper div with lexxy-component class' do
      render_inline(described_class.new)

      expect(page).to have_css('div.lexxy-component')
    end

    it 'renders a lexxy-editor custom element' do
      render_inline(described_class.new)

      expect(page).to have_css('lexxy-editor')
    end

    it 'renders with name attribute' do
      render_inline(described_class.new(name: 'post[body]'))

      expect(page).to have_css('lexxy-editor[name="post[body]"]')
    end

    it 'renders with placeholder attribute' do
      render_inline(described_class.new(placeholder: 'Write something...'))

      expect(page).to have_css('lexxy-editor[placeholder="Write something..."]')
    end

    it 'renders with value attribute' do
      render_inline(described_class.new(value: '<p>Hello</p>'))

      expect(page).to have_css('lexxy-editor[value]')
    end

    it 'renders block content inside the editor' do
      render_inline(described_class.new) { 'Initial content' }

      expect(page).to have_text('Initial content')
    end
  end

  describe 'boolean attributes' do
    it 'renders required attribute when true' do
      render_inline(described_class.new(required: true))

      expect(page).to have_css('lexxy-editor[required]')
    end

    it 'omits required attribute when false' do
      render_inline(described_class.new(required: false))

      expect(page).not_to have_css('lexxy-editor[required]')
    end

    it 'renders disabled attribute when true' do
      render_inline(described_class.new(disabled: true))

      expect(page).to have_css('lexxy-editor[disabled]')
    end

    it 'omits disabled attribute when false' do
      render_inline(described_class.new(disabled: false))

      expect(page).not_to have_css('lexxy-editor[disabled]')
    end

    it 'renders autofocus attribute when true' do
      render_inline(described_class.new(autofocus: true))

      expect(page).to have_css('lexxy-editor[autofocus]')
    end

    it 'omits autofocus attribute when false' do
      render_inline(described_class.new(autofocus: false))

      expect(page).not_to have_css('lexxy-editor[autofocus]')
    end
  end

  describe 'toolbar' do
    it 'omits toolbar attribute when true (default)' do
      render_inline(described_class.new(toolbar: true))

      expect(page).not_to have_css('lexxy-editor[toolbar]')
    end

    it 'renders toolbar="false" when false' do
      render_inline(described_class.new(toolbar: false))

      expect(page).to have_css('lexxy-editor[toolbar="false"]')
    end

    it 'renders toolbar with external ID when string' do
      render_inline(described_class.new(toolbar: 'my-toolbar'))

      expect(page).to have_css('lexxy-editor[toolbar="my-toolbar"]')
    end
  end

  describe 'editor modes' do
    it 'renders attachments="false" when disabled' do
      render_inline(described_class.new(attachments: false))

      expect(page).to have_css('lexxy-editor[attachments="false"]')
    end

    it 'omits attachments attribute when true (default)' do
      render_inline(described_class.new(attachments: true))

      expect(page).not_to have_css('lexxy-editor[attachments]')
    end

    it 'renders markdown attribute when enabled' do
      render_inline(described_class.new(markdown: true))

      expect(page).to have_css('lexxy-editor[markdown]')
    end

    it 'omits markdown attribute when false (default)' do
      render_inline(described_class.new(markdown: false))

      expect(page).not_to have_css('lexxy-editor[markdown]')
    end

    it 'renders multiLine="false" when disabled' do
      render_inline(described_class.new(multi_line: false))

      # Nokogiri lowercases HTML attributes; camelCase renders correctly in browsers
      expect(page).to have_css('lexxy-editor[multiline="false"]')
    end

    it 'omits multiLine attribute when true (default)' do
      render_inline(described_class.new(multi_line: true))

      expect(page).not_to have_css('lexxy-editor[multiline]')
    end

    it 'renders richText="false" when disabled' do
      render_inline(described_class.new(rich_text: false))

      # Nokogiri lowercases HTML attributes; camelCase renders correctly in browsers
      expect(page).to have_css('lexxy-editor[richtext="false"]')
    end

    it 'omits richText attribute when true (default)' do
      render_inline(described_class.new(rich_text: true))

      expect(page).not_to have_css('lexxy-editor[richtext]')
    end

    it 'renders preset attribute' do
      render_inline(described_class.new(preset: :basic))

      expect(page).to have_css('lexxy-editor[preset="basic"]')
    end
  end

  describe 'prompt slots' do
    it 'renders a single prompt' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention')
      end

      expect(page).to have_css('lexxy-prompt[trigger="@"][name="mention"]')
    end

    it 'renders multiple prompts' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention')
        editor.with_prompt(trigger: '#', name: 'tag')
      end

      expect(page).to have_css('lexxy-prompt[trigger="@"][name="mention"]')
      expect(page).to have_css('lexxy-prompt[trigger="#"][name="tag"]')
    end

    it 'renders prompt with src attribute' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention', src: '/people')
      end

      expect(page).to have_css('lexxy-prompt[src="/people"]')
    end

    it 'renders prompt with remote-filtering attribute' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention', remote_filtering: true)
      end

      expect(page).to have_css('lexxy-prompt[remote-filtering]')
    end

    it 'renders prompt with insert-editable-text attribute' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention', insert_editable_text: true)
      end

      expect(page).to have_css('lexxy-prompt[insert-editable-text]')
    end

    it 'renders prompt with empty-results attribute' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention', empty_results: 'No users found')
      end

      expect(page).to have_css('lexxy-prompt[empty-results="No users found"]')
    end

    it 'renders prompt with supports-space-in-searches attribute' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention', supports_space_in_searches: true)
      end

      expect(page).to have_css('lexxy-prompt[supports-space-in-searches]')
    end

    it 'renders prompt content (suggestion items)' do
      render_inline(described_class.new) do |editor|
        editor.with_prompt(trigger: '@', name: 'mention') do
          '<option value="1">Alice</option>'.html_safe
        end
      end

      expect(page).to have_css('lexxy-prompt option[value="1"]', text: 'Alice')
    end
  end

  describe 'custom classes' do
    it 'appends custom classes to wrapper' do
      render_inline(described_class.new(class: 'my-custom-class'))

      expect(page).to have_css('div.lexxy-component.my-custom-class')
    end
  end

  describe 'data attributes' do
    it 'passes through data attributes to the editor' do
      render_inline(described_class.new(data: { controller: 'my-controller' }))

      expect(page).to have_css('lexxy-editor[data-controller="my-controller"]')
    end
  end

  describe 'Active Storage upload URLs' do
    it 'includes data-direct-upload-url when attachments enabled' do
      render_inline(described_class.new(attachments: true))

      expect(page).to have_css('lexxy-editor[data-direct-upload-url]')
    end

    it 'includes data-blob-url-template when attachments enabled' do
      render_inline(described_class.new(attachments: true))

      expect(page).to have_css('lexxy-editor[data-blob-url-template]')
    end

    it 'omits upload URLs when attachments disabled' do
      render_inline(described_class.new(attachments: false))

      expect(page).not_to have_css('lexxy-editor[data-direct-upload-url]')
      expect(page).not_to have_css('lexxy-editor[data-blob-url-template]')
    end
  end
end
