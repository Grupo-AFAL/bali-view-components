# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::Avatar::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Avatar::Component.new(**options) }
  let(:helper) { FormHelperTest.new(nil) }

  describe 'basic rendering' do
    it 'renders the avatar component with DaisyUI classes' do
      helper.form_with(url: '/') do |form|
        options.merge!(method: :test, form: form, placeholder_url: '/default-avatar.png')
        render_inline(component)
      end

      expect(page).to have_css '.avatar-component.relative'
      expect(page).to have_css '.avatar-component .avatar'
      expect(page).to have_css '.avatar-component img.rounded-full'
      expect(page).to have_css 'input[type="file"][accept=".jpg, .jpeg, .png,"]'
    end

    it 'renders camera icon for upload' do
      helper.form_with(url: '/') do |form|
        options.merge!(method: :test, form: form, placeholder_url: '/default-avatar.png')
        render_inline(component)
      end

      expect(page).to have_css '.avatar-component label'
    end
  end

  describe 'with custom picture' do
    it 'renders the provided picture instead of placeholder' do
      helper.form_with(url: '/') do |form|
        options.merge!(method: :test, form: form, placeholder_url: '/default-avatar.png')
        render_inline(component) do |c|
          c.with_picture(image_url: '/custom-avatar.png')
        end
      end

      expect(page).to have_css 'img[src*="custom-avatar.png"]'
    end
  end

  describe 'sizes' do
    %i[xs sm md lg xl].each do |size|
      it "renders #{size} size" do
        helper.form_with(url: '/') do |form|
          options.merge!(method: :test, form: form, placeholder_url: '/default.png', size: size)
          render_inline(component)
        end

        expect(page).to have_css ".avatar-component .avatar.w-#{if size == :xl
                                                                  '32'
                                                                elsif size == :lg
                                                                  '24'
                                                                elsif size == :md
                                                                  '16'
                                                                else
                                                                  size == :sm ? '12' : '8'
                                                                end}"
      end
    end
  end
end
