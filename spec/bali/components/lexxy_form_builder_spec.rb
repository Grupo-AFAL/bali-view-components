# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#lexxy_editor_group' do
    it 'renders a fieldset wrapper' do
      result = builder.lexxy_editor_group(:synopsis)

      expect(result).to have_css('fieldset.fieldset')
    end

    it 'renders a legend label' do
      result = builder.lexxy_editor_group(:synopsis)

      expect(result).to have_css('legend.fieldset-legend', text: 'Synopsis')
    end

    it 'renders a lexxy-editor inside the wrapper' do
      result = builder.lexxy_editor_group(:synopsis)

      expect(result).to have_css('fieldset lexxy-editor[name="movie[synopsis]"]')
    end
  end

  describe '#lexxy_editor' do
    it 'renders a lexxy-editor element' do
      result = builder.lexxy_editor(:synopsis)

      expect(result).to have_css('lexxy-editor')
    end

    it 'sets the correct form field name' do
      result = builder.lexxy_editor(:synopsis)

      expect(result).to have_css('lexxy-editor[name="movie[synopsis]"]')
    end

    it 'populates value from model attribute' do
      resource.synopsis = 'A great movie'
      result = builder.lexxy_editor(:synopsis)

      expect(result).to have_css('lexxy-editor[value="A great movie"]')
    end

    it 'omits value attribute when model attribute is blank' do
      resource.synopsis = nil
      result = builder.lexxy_editor(:synopsis)

      expect(result).not_to have_css('lexxy-editor[value]')
    end

    it 'passes placeholder option through' do
      result = builder.lexxy_editor(:synopsis, placeholder: 'Write a synopsis...')

      expect(result).to have_css('lexxy-editor[placeholder="Write a synopsis..."]')
    end

    it 'passes toolbar option through' do
      result = builder.lexxy_editor(:synopsis, toolbar: false)

      expect(result).to have_css('lexxy-editor[toolbar="false"]')
    end

    it 'passes attachments option through' do
      result = builder.lexxy_editor(:synopsis, attachments: false)

      expect(result).to have_css('lexxy-editor[attachments="false"]')
    end

    it 'passes markdown option through' do
      result = builder.lexxy_editor(:synopsis, markdown: true)

      expect(result).to have_css('lexxy-editor[markdown]')
    end

    context 'with validation errors' do
      before { resource.errors.add(:synopsis, 'is required') }

      it 'applies error class to wrapper' do
        result = builder.lexxy_editor(:synopsis)

        expect(result).to have_css('div.lexxy-component.input-error')
      end
    end

    context 'with block for prompts' do
      it 'forwards block to component' do
        result = builder.lexxy_editor(:synopsis) do |editor|
          editor.with_prompt(trigger: '@', name: 'mention')
        end

        expect(result).to have_css('lexxy-editor lexxy-prompt[trigger="@"][name="mention"]')
      end
    end
  end
end
