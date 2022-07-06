# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::DeleteLink::Component, type: :component do
  before { @options = { href: '/delete-url' } }

  let(:component) { Bali::DeleteLink::Component.new(**@options) }

  subject { rendered_component }

  it 'renders a delete link' do
    render_inline(component)

    expect(rendered_component).to have_css 'button.has-text-danger.is-text', text: 'Delete'
    expect(rendered_component).to have_css "[data-turbo-confirm='Are you sure?']"
    expect(rendered_component).to have_css "[action='/delete-url']"
  end

  it 'overrides the link name' do
    @options.merge!(name: 'Cancel')
    render_inline(component)

    expect(rendered_component).to have_css 'button.has-text-danger.is-text', text: 'Cancel'
  end

  it 'overrides the link confirm message' do
    @options.merge!(confirm: 'Continue?')
    render_inline(component)

    expect(rendered_component).to have_css "[data-turbo-confirm='Continue?']"
  end

  it 'add a css class to the link' do
    @options.merge!(class: 'is-large')
    render_inline(component)

    expect(rendered_component).to have_css 'button.has-text-danger.is-text.is-large'
  end

  it 'raises an error without model or href' do
    @options.merge!(href: nil)

    expect { render_inline(component) }.to raise_error(Bali::DeleteLink::Component::MissingURL)
  end

  it 'renders a delete link with custom form classes' do
    @options.merge!(form_class: 'has-background-success')
    render_inline(component)

    expect(rendered_component).to have_css 'button.has-text-danger.is-text', text: 'Delete'
    expect(rendered_component).to have_css 'form.button_to.has-background-success'
  end

  context 'with active record model' do
    before do
      model_name = double(
        'model_name', i18n_key: 'model', human: 'model', name: 'model', route_key: 'root'
      )
      to_model = double(model_name: model_name, persisted?: false)
      model = double('model', id: 1, model_name: model_name, to_model: to_model)

      @options = { model: model }
    end

    it 'renders a delete link' do
      allow(component).to receive(:href) { '/models/1' }

      render_inline(component)

      expect(rendered_component).to have_css 'button.has-text-danger.is-text', text: 'Delete'
      expect(rendered_component).to include 'Are you sure you want to delete'
      expect(rendered_component).to have_css "[action='/models/1']"
    end

    it 'overrides the default model href' do
      @options.merge!(href: '/delete-url')
      render_inline(component)

      expect(rendered_component).to have_css "[action='/delete-url']"
    end
  end

  context 'when the hover card link component is in use' do
    it 'renders a delete link disabled' do
      @options.merge!(disabled: true)
      render_inline(component)

      expect(rendered_component).to have_css '[disabled="disabled"]'
    end
  end
end
