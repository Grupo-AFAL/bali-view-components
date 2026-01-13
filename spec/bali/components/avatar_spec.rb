# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::Avatar::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Avatar::Component.new(**options) }
  let(:helper) { FormHelperTest.new(nil) }

  describe 'display-only mode' do
    it 'renders without form (display only)' do
      options.merge!(placeholder_url: '/avatar.png', size: :lg)
      render_inline(component)

      expect(page).to have_css '.avatar-component.avatar'
      expect(page).to have_css 'img[src*="avatar.png"]'
      expect(page).not_to have_css 'label[aria-label="Upload avatar image"]'
    end

    it 'does not show upload button when no form' do
      options.merge!(placeholder_url: '/avatar.png')
      render_inline(component)

      expect(page).not_to have_css '.bg-base-200.rounded-full.w-10'
    end
  end

  describe 'upload mode' do
    it 'renders the avatar component with DaisyUI classes' do
      helper.form_with(url: '/') do |form|
        options.merge!(method: :test, form: form, placeholder_url: '/default-avatar.png')
        render_inline(component)
      end

      expect(page).to have_css '.avatar-component.avatar.relative'
      expect(page).to have_css '.avatar-component img.object-cover'
      expect(page).to have_css 'input[type="file"][accept=".jpg, .jpeg, .png"]'
    end

    it 'renders camera icon for upload with accessibility label' do
      helper.form_with(url: '/') do |form|
        options.merge!(method: :test, form: form, placeholder_url: '/default-avatar.png')
        render_inline(component)
      end

      expect(page).to have_css '.avatar-component label[aria-label="Upload avatar image"]'
    end

    it 'renders upload button with proper DaisyUI styling' do
      helper.form_with(url: '/') do |form|
        options.merge!(method: :test, form: form, placeholder_url: '/default-avatar.png')
        render_inline(component)
      end

      expect(page).to have_css '.avatar-component .rounded-full.w-10.h-10.bg-base-200'
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

  describe 'shapes' do
    it 'renders square shape by default' do
      options.merge!(placeholder_url: '/avatar.png')
      render_inline(component)

      expect(page).to have_css '.avatar-component .rounded.aspect-square'
    end

    it 'renders rounded shape' do
      options.merge!(placeholder_url: '/avatar.png', shape: :rounded)
      render_inline(component)

      expect(page).to have_css '.avatar-component .rounded-xl'
    end

    it 'renders circle shape' do
      options.merge!(placeholder_url: '/avatar.png', shape: :circle)
      render_inline(component)

      expect(page).to have_css '.avatar-component .rounded-full'
    end
  end

  describe 'masks' do
    {
      heart: 'mask-heart',
      squircle: 'mask-squircle',
      hexagon: 'mask-hexagon-2',
      triangle: 'mask-triangle',
      diamond: 'mask-diamond',
      pentagon: 'mask-pentagon',
      star: 'mask-star'
    }.each do |mask, expected_class|
      it "renders #{mask} mask" do
        options.merge!(placeholder_url: '/avatar.png', mask: mask)
        render_inline(component)

        expect(page).to have_css ".avatar-component .mask.#{expected_class}"
      end
    end
  end

  describe 'sizes' do
    {
      xs: 'w-8',
      sm: 'w-12',
      md: 'w-16',
      lg: 'w-24',
      xl: 'w-32'
    }.each do |size, expected_class|
      it "renders #{size} size with #{expected_class}" do
        options.merge!(placeholder_url: '/default.png', size: size, shape: :circle)
        render_inline(component)

        expect(page).to have_css ".avatar-component .#{expected_class}.rounded-full"
      end
    end
  end

  describe 'placeholder' do
    it 'renders placeholder with initials' do
      options.merge!(size: :lg, shape: :circle)
      render_inline(component) do |c|
        c.with_placeholder { 'JD' }
      end

      expect(page).to have_css '.avatar-component.avatar-placeholder'
      expect(page).to have_css '.bg-neutral.text-neutral-content'
      expect(page).to have_text 'JD'
    end

    it 'applies correct text size for placeholder' do
      options.merge!(size: :xl, shape: :circle)
      render_inline(component) do |c|
        c.with_placeholder { 'AB' }
      end

      expect(page).to have_css '.text-3xl'
    end
  end

  describe 'presence indicator' do
    it 'renders online status' do
      options.merge!(placeholder_url: '/default.png', status: :online, shape: :circle)
      render_inline(component)

      expect(page).to have_css '.avatar-component.avatar-online'
    end

    it 'renders offline status' do
      options.merge!(placeholder_url: '/default.png', status: :offline, shape: :circle)
      render_inline(component)

      expect(page).to have_css '.avatar-component.avatar-offline'
    end
  end

  describe 'ring styling' do
    it 'renders with primary ring' do
      options.merge!(placeholder_url: '/default.png', ring: :primary, shape: :circle)
      render_inline(component)

      expect(page).to have_css '.ring-2.ring-primary.ring-offset-2'
    end

    it 'renders with success ring' do
      options.merge!(placeholder_url: '/default.png', ring: :success, shape: :circle)
      render_inline(component)

      expect(page).to have_css '.ring-2.ring-success'
    end

    it 'renders without ring when not specified' do
      options.merge!(placeholder_url: '/default.png', shape: :circle)
      render_inline(component)

      expect(page).not_to have_css '.ring-2'
    end
  end

  describe 'combined features' do
    it 'renders with size, shape, ring, and status together' do
      options.merge!(
        placeholder_url: '/default.png',
        size: :lg,
        shape: :circle,
        ring: :primary,
        status: :online
      )
      render_inline(component)

      expect(page).to have_css '.avatar-component.avatar-online'
      expect(page).to have_css '.w-24.rounded-full.ring-2.ring-primary'
    end
  end
end

RSpec.describe Bali::Avatar::Group::Component, type: :component do
  describe 'basic rendering' do
    it 'renders avatar group container' do
      render_inline(described_class.new) do |group|
        group.with_avatar(placeholder_url: '/avatar1.png', size: :md, shape: :circle)
        group.with_avatar(placeholder_url: '/avatar2.png', size: :md, shape: :circle)
      end

      expect(page).to have_css '.avatar-group.-space-x-6'
      expect(page).to have_css '.avatar', count: 2
    end
  end

  describe 'spacing' do
    it 'renders tight spacing' do
      render_inline(described_class.new(spacing: :tight)) do |group|
        group.with_avatar(placeholder_url: '/avatar.png', size: :md, shape: :circle)
      end

      expect(page).to have_css '.avatar-group.-space-x-4'
    end

    it 'renders loose spacing' do
      render_inline(described_class.new(spacing: :loose)) do |group|
        group.with_avatar(placeholder_url: '/avatar.png', size: :md, shape: :circle)
      end

      expect(page).to have_css '.avatar-group.-space-x-8'
    end
  end

  describe 'with counter' do
    it 'renders counter at the end' do
      render_inline(described_class.new) do |group|
        group.with_avatar(placeholder_url: '/avatar.png', size: :md, shape: :circle)
        group.with_avatar(placeholder_url: '/avatar.png', size: :md, shape: :circle)
        group.with_counter { '+99' }
      end

      expect(page).to have_css '.avatar-group .avatar-placeholder'
      expect(page).to have_text '+99'
    end
  end
end
