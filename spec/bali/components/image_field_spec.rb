# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::ImageField::Component, type: :component do
  let(:options) { {} }
  let(:component) { described_class.new(**options) }

  describe 'default rendering' do
    it 'renders with placeholder image by default' do
      render_inline(component)

      expect(page).to have_css 'div.image-field-component'
      expect(page).to have_css 'img[src*="placehold.jp"]'
    end

    it 'applies image-field controller' do
      render_inline(component)

      expect(page).to have_css '[data-controller="image-field"]'
    end

    it 'applies output target to displayed image' do
      render_inline(component)

      expect(page).to have_css 'img[data-image-field-target="output"]'
    end

    it 'applies default size class (md)' do
      render_inline(component)

      expect(page).to have_css 'img.size-32'
    end
  end

  describe 'with custom src' do
    it 'renders the provided image' do
      component = described_class.new(src: 'https://example.com/avatar.png')
      render_inline(component)

      expect(page).to have_css 'img[src="https://example.com/avatar.png"]'
    end

    it 'falls back to placeholder_url when src is nil' do
      options.merge!(placeholder_url: 'https://example.com/placeholder.png')
      render_inline(component)

      expect(page).to have_css 'img[src="https://example.com/placeholder.png"]'
    end
  end

  describe 'with custom placeholder_url' do
    it 'uses custom placeholder' do
      component = described_class.new(placeholder_url: 'https://example.com/my-placeholder.png')
      render_inline(component)

      expect(page).to have_css 'img[src="https://example.com/my-placeholder.png"]'
    end
  end

  describe 'sizes' do
    described_class::SIZES.each do |size, expected_class|
      it "renders #{size} size with #{expected_class}" do
        component = described_class.new(size: size)
        render_inline(component)

        expect(page).to have_css "img.#{expected_class}"
      end
    end
  end

  describe 'image styling' do
    it 'applies rounded and object-cover classes' do
      render_inline(component)

      expect(page).to have_css 'img.rounded-lg.object-cover'
    end

    it 'applies empty alt by default for accessibility' do
      render_inline(component)

      expect(page).to have_css 'img[alt=""]'
    end
  end

  describe 'styling classes' do
    it 'applies base component classes' do
      render_inline(component)

      expect(page).to have_css '.image-field-component.group.relative.w-fit'
    end
  end

  describe 'options passthrough' do
    it 'passes extra options to container' do
      options.merge!(data: { test: 'value' }, id: 'my-image-field')
      render_inline(component)

      expect(page).to have_css '[data-test="value"][id="my-image-field"]'
    end

    it 'merges with default controller' do
      options.merge!(data: { custom: 'attr' })
      render_inline(component)

      expect(page).to have_css '[data-controller="image-field"][data-custom="attr"]'
    end

    it 'allows custom classes' do
      options.merge!(class: 'my-custom-class')
      render_inline(component)

      expect(page).to have_css '.image-field-component.my-custom-class'
    end
  end
end

RSpec.describe Bali::ImageField::Input::Component, type: :component do
  let(:helper) { FormHelperTest.new(nil) }

  describe 'basic rendering' do
    it 'renders file input with label container' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'label.image-input-container'
      expect(page).to have_css 'input[type="file"]'
    end

    it 'renders camera icon by default' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'label svg', visible: :all
    end

    it 'applies hover overlay classes' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'label.absolute.inset-0.flex.cursor-pointer'
    end

    it 'hides the file input visually' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'input[type="file"].hidden'
    end
  end

  describe 'file formats' do
    it 'accepts default formats' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      input = page.find('input[type="file"]')
      expect(input[:accept]).to eq('.jpg, .jpeg, .png, .webp')
    end

    it 'accepts custom formats' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, formats: %i[gif png]))
      end

      input = page.find('input[type="file"]')
      expect(input[:accept]).to eq('.gif, .png')
    end
  end

  describe 'custom icon' do
    it 'renders custom icon' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, icon_name: 'upload'))
      end

      expect(page).to have_css 'label svg', visible: :all
    end
  end

  describe 'stimulus data attributes' do
    it 'adds input target' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'input[data-image-field-target="input"]'
    end

    it 'adds change action' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'input[data-action="change->image-field#show"]'
    end
  end
end

RSpec.describe 'ImageField with input slot', type: :component do
  let(:helper) { FormHelperTest.new(nil) }

  describe 'with input slot' do
    it 'renders input and placeholder image' do
      helper.form_with(url: '/') do |form|
        render_inline(Bali::ImageField::Component.new) do |c|
          c.with_input(form: form, method: :avatar)
        end
      end

      expect(page).to have_css 'img[data-image-field-target="output"]'
      expect(page).to have_css 'img[data-image-field-target="placeholder"]'
      expect(page).to have_css 'label.image-input-container'
    end

    it 'renders default clear button using Bali::Button' do
      helper.form_with(url: '/') do |form|
        render_inline(Bali::ImageField::Component.new) do |c|
          c.with_input(form: form, method: :avatar)
        end
      end

      expect(page).to have_css '.clear-image-button'
      expect(page).to have_css 'button.btn[data-action="image-field#clear"]'
      expect(page).to have_css 'button[aria-label]'
    end
  end

  describe 'with custom clear button' do
    it 'renders custom clear button when provided' do
      helper.form_with(url: '/') do |form|
        render_inline(Bali::ImageField::Component.new) do |c|
          c.with_input(form: form, method: :avatar)
          c.with_clear_button do
            '<button class="custom-clear">Clear</button>'.html_safe
          end
        end
      end

      expect(page).to have_css '.custom-clear'
      expect(page).to have_text 'Clear'
    end
  end

  describe 'without input slot' do
    it 'does not render placeholder, input, or clear button' do
      render_inline(Bali::ImageField::Component.new)

      expect(page).not_to have_css 'img[data-image-field-target="placeholder"]'
      expect(page).not_to have_css 'label.image-input-container'
      expect(page).not_to have_css '.clear-image-button'
    end
  end
end
