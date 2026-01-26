# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::DeleteLink::Component, type: :component do
  before { @options = { href: '/delete-url' } }

  let(:component) { Bali::DeleteLink::Component.new(**@options) }

  it 'renders a delete link' do
    render_inline(component)

    expect(page).to have_css 'button.text-error.btn-ghost', text: 'Delete'
    expect(page).to have_css "[data-turbo-confirm='Are you sure?']"
    expect(page).to have_css "[action='/delete-url']"
  end

  it 'overrides the link name' do
    @options.merge!(name: 'Cancel')
    render_inline(component)

    expect(page).to have_css 'button.text-error.btn-ghost', text: 'Cancel'
  end

  it 'overrides the link confirm message' do
    @options.merge!(confirm: 'Continue?')
    render_inline(component)

    expect(page).to have_css "[data-turbo-confirm='Continue?']"
  end

  it 'add a css class to the link' do
    @options.merge!(class: 'btn-lg')
    render_inline(component)

    expect(page).to have_css 'button.text-error.btn-ghost.btn-lg'
  end

  it 'raises an error without model or href' do
    @options.merge!(href: nil)

    expect { render_inline(component) }.to raise_error(Bali::DeleteLink::Component::MissingURL)
  end

  it 'renders a delete link with custom form classes' do
    @options.merge!(form_class: 'bg-success')
    render_inline(component)

    expect(page).to have_css 'button.text-error.btn-ghost', text: 'Delete'
    expect(page).to have_css 'form.inline-block.bg-success'
  end

  describe 'sizes' do
    described_class::SIZES.each do |size, css_class|
      next if css_class.blank?

      it "applies #{size} size class" do
        @options.merge!(size: size)
        render_inline(component)

        expect(page).to have_css "button.btn.#{css_class}"
      end
    end
  end

  describe 'icon' do
    it 'renders with icon when icon: true' do
      @options.merge!(icon: true)
      render_inline(component)

      expect(page).to have_css 'button .icon-component'
      expect(page).to have_css 'button span', text: 'Delete'
    end

    it 'does not render icon by default' do
      render_inline(component)

      expect(page).not_to have_css '.icon-component'
    end
  end

  describe 'skip_confirm' do
    it 'skips confirmation when skip_confirm: true' do
      @options.merge!(skip_confirm: true)
      render_inline(component)

      expect(page).not_to have_css '[data-turbo-confirm]'
    end
  end

  describe 'authorization' do
    it 'does not render when authorized: false' do
      @options.merge!(authorized: false)
      render_inline(component)

      expect(page).not_to have_css 'button'
      expect(page).not_to have_css 'form'
    end

    it 'renders when authorized: true (default)' do
      render_inline(component)

      expect(page).to have_css 'button'
    end
  end

  describe 'block content' do
    it 'uses block content as name' do
      render_inline(component) { 'Remove Item' }

      expect(page).to have_css 'button span', text: 'Remove Item'
    end
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

      expect(page).to have_css 'button.text-error.btn-ghost', text: 'Delete'
      expect(page).to have_css "[action='/models/1']"
    end

    it 'overrides the default model href' do
      @options.merge!(href: '/delete-url')
      render_inline(component)

      expect(page).to have_css "[action='/delete-url']"
    end
  end

  context 'when the hover card link component is in use' do
    it 'renders a delete link disabled' do
      @options.merge!(disabled: true)
      render_inline(component)

      expect(page).to have_css '[disabled="disabled"]'
    end

    it 'applies btn-disabled class when disabled' do
      @options.merge!(disabled: true)
      render_inline(component)

      expect(page).to have_css 'a.btn-disabled'
    end

    it 'preserves custom classes when disabled' do
      @options.merge!(disabled: true, class: 'custom-class')
      render_inline(component)

      expect(page).to have_css 'a.btn-disabled.custom-class'
    end
  end
end
