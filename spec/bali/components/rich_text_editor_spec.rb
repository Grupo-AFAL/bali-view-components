# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::RichTextEditor::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::RichTextEditor::Component.new(**options) }

  before do
    allow(Bali).to receive(:rich_text_editor_enabled).and_return(true)
  end

  it 'renders richtexteditor component' do
    render_inline(component)

    expect(page).to have_css 'div.rich-text-editor-component'
  end
end
