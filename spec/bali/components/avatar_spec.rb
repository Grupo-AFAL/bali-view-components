# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::Avatar::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Avatar::Component.new(**options) }

  describe 'display-only mode' do
    it 'renders with src parameter' do
      options.merge!(src: '/avatar.png', size: :lg)
      render_inline(component)

      expect(page).to have_css '.avatar'
      expect(page).to have_css 'img[src*="avatar.png"]'
    end

    it 'renders with default size :md and shape :circle' do
      options.merge!(src: '/avatar.png')
      render_inline(component)

      expect(page).to have_css '.avatar .w-16.rounded-full'
    end
  end

  describe 'with custom picture slot' do
    it 'renders the provided picture instead of src' do
      options.merge!(src: '/default-avatar.png')
      render_inline(component) do |c|
        c.with_picture(image_url: '/custom-avatar.png')
      end

      expect(page).to have_css 'img[src*="custom-avatar.png"]'
      expect(page).not_to have_css 'img[src*="default-avatar.png"]'
    end

    it 'passes data attributes through to picture' do
      render_inline(component) do |c|
        c.with_picture(image_url: '/avatar.png', data: { test: 'value' })
      end

      expect(page).to have_css 'img[data-test="value"]'
    end
  end

  describe 'shapes' do
    it 'renders circle shape by default' do
      options.merge!(src: '/avatar.png')
      render_inline(component)

      expect(page).to have_css '.avatar .rounded-full.aspect-square'
    end

    it 'renders square shape' do
      options.merge!(src: '/avatar.png', shape: :square)
      render_inline(component)

      expect(page).to have_css '.avatar .rounded'
    end

    it 'renders rounded shape' do
      options.merge!(src: '/avatar.png', shape: :rounded)
      render_inline(component)

      expect(page).to have_css '.avatar .rounded-xl'
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
        options.merge!(src: '/avatar.png', mask: mask)
        render_inline(component)

        expect(page).to have_css ".avatar .mask.#{expected_class}"
      end
    end

    it 'does not add aspect-square when mask is applied' do
      options.merge!(src: '/avatar.png', mask: :heart)
      render_inline(component)

      expect(page).not_to have_css '.aspect-square'
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
        options.merge!(src: '/default.png', size: size)
        render_inline(component)

        expect(page).to have_css ".avatar .#{expected_class}"
      end
    end
  end

  describe 'placeholder' do
    it 'renders placeholder with initials' do
      options.merge!(size: :lg, shape: :circle)
      render_inline(component) do |c|
        c.with_placeholder { 'JD' }
      end

      expect(page).to have_css '.avatar.avatar-placeholder'
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

    it 'does not show placeholder when src is provided' do
      options.merge!(src: '/avatar.png', size: :lg)
      render_inline(component) do |c|
        c.with_placeholder { 'JD' }
      end

      expect(page).not_to have_css '.avatar-placeholder'
      expect(page).to have_css 'img[src*="avatar.png"]'
    end
  end

  describe 'presence indicator' do
    it 'renders online status' do
      options.merge!(src: '/default.png', status: :online)
      render_inline(component)

      expect(page).to have_css '.avatar.avatar-online'
    end

    it 'renders offline status' do
      options.merge!(src: '/default.png', status: :offline)
      render_inline(component)

      expect(page).to have_css '.avatar.avatar-offline'
    end
  end

  describe 'ring styling' do
    it 'renders with primary ring' do
      options.merge!(src: '/default.png', ring: :primary)
      render_inline(component)

      expect(page).to have_css '.ring-2.ring-primary.ring-offset-2'
    end

    it 'renders with success ring' do
      options.merge!(src: '/default.png', ring: :success)
      render_inline(component)

      expect(page).to have_css '.ring-2.ring-success'
    end

    it 'renders without ring when not specified' do
      options.merge!(src: '/default.png')
      render_inline(component)

      expect(page).not_to have_css '.ring-2'
    end
  end

  describe 'combined features' do
    it 'renders with size, shape, ring, and status together' do
      options.merge!(
        src: '/default.png',
        size: :lg,
        shape: :circle,
        ring: :primary,
        status: :online
      )
      render_inline(component)

      expect(page).to have_css '.avatar.avatar-online'
      expect(page).to have_css '.w-24.rounded-full.ring-2.ring-primary'
    end
  end

  describe 'options passthrough' do
    it 'passes extra options to container' do
      options.merge!(src: '/avatar.png', data: { test: 'value' }, id: 'my-avatar')
      render_inline(component)

      expect(page).to have_css '.avatar[data-test="value"][id="my-avatar"]'
    end
  end

  describe 'accessibility' do
    it 'uses alt text when provided' do
      options.merge!(src: '/avatar.png', alt: 'User profile picture')
      render_inline(component)

      expect(page).to have_css 'img[alt="User profile picture"]'
    end

    it 'uses empty alt by default for decorative images' do
      options.merge!(src: '/avatar.png')
      render_inline(component)

      expect(page).to have_css 'img[alt=""]'
    end
  end
end

RSpec.describe Bali::Avatar::Upload::Component, type: :component do
  let(:helper) { FormHelperTest.new(nil) }

  describe 'upload functionality' do
    it 'renders with upload button overlay' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, src: '/default-avatar.png'))
      end

      expect(page).to have_css '[data-controller="avatar"]'
      expect(page).to have_css 'label[aria-label="Upload avatar image"]'
      expect(page).to have_css 'input[type="file"]'
    end

    it 'wraps the Avatar component' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, src: '/avatar.png',
                                          size: :xl))
      end

      expect(page).to have_css '.avatar .w-32'
    end

    it 'renders camera icon' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, src: '/avatar.png'))
      end

      # Check for the icon component being rendered
      expect(page).to have_css 'label svg', visible: :all
    end

    it 'accepts custom formats' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, formats: %w[gif png]))
      end

      expect(page).to have_css 'input[type="file"][accept=".gif, .png"]'
    end

    it 'uses default formats when not specified' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'input[type="file"][accept=".jpg, .jpeg, .png, .webp"]'
    end

    it 'passes size and shape to avatar' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, size: :lg, shape: :rounded))
      end

      expect(page).to have_css '.avatar .w-24.rounded-xl'
    end

    it 'adds stimulus data attributes' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar, src: '/avatar.png'))
      end

      expect(page).to have_css '[data-controller="avatar"]'
      expect(page).to have_css 'img[data-avatar-target="output"]'
      expect(page).to have_css 'input[data-avatar-target="input"]'
      expect(page).to have_css 'input[data-action="change->avatar#showImage"]'
    end

    it 'renders output target even without src for Stimulus controller' do
      helper.form_with(url: '/') do |form|
        render_inline(described_class.new(form: form, method: :avatar))
      end

      expect(page).to have_css 'img[data-avatar-target="output"]'
    end
  end
end

RSpec.describe Bali::Avatar::Group::Component, type: :component do
  describe 'basic rendering' do
    it 'renders avatar group container' do
      render_inline(described_class.new) do |group|
        group.with_avatar(src: '/avatar1.png', size: :sm)
        group.with_avatar(src: '/avatar2.png', size: :sm)
      end

      expect(page).to have_css '.avatar-group.-space-x-6'
      expect(page).to have_css '.avatar', count: 2
    end
  end

  describe 'spacing' do
    it 'renders tight spacing' do
      render_inline(described_class.new(spacing: :tight)) do |group|
        group.with_avatar(src: '/avatar.png', size: :sm)
      end

      expect(page).to have_css '.avatar-group.-space-x-4'
    end

    it 'renders normal spacing by default' do
      render_inline(described_class.new) do |group|
        group.with_avatar(src: '/avatar.png', size: :sm)
      end

      expect(page).to have_css '.avatar-group.-space-x-6'
    end

    it 'renders loose spacing' do
      render_inline(described_class.new(spacing: :loose)) do |group|
        group.with_avatar(src: '/avatar.png', size: :sm)
      end

      expect(page).to have_css '.avatar-group.-space-x-8'
    end
  end

  describe 'with counter' do
    it 'renders counter at the end' do
      render_inline(described_class.new) do |group|
        group.with_avatar(src: '/avatar.png', size: :sm)
        group.with_avatar(src: '/avatar.png', size: :sm)
        group.with_counter { '+99' }
      end

      expect(page).to have_css '.avatar-group .avatar-placeholder'
      expect(page).to have_text '+99'
    end

    it 'uses group size for counter' do
      render_inline(described_class.new(size: :lg)) do |group|
        group.with_avatar(src: '/avatar.png', size: :lg)
        group.with_counter { '+5' }
      end

      expect(page).to have_css '.avatar-placeholder .w-24'
    end
  end

  describe 'size inheritance' do
    it 'avatars inherit size from group by default' do
      render_inline(described_class.new(size: :lg)) do |group|
        group.with_avatar(src: '/avatar.png')
      end

      expect(page).to have_css '.avatar .w-24'
    end

    it 'avatars can override inherited size' do
      render_inline(described_class.new(size: :lg)) do |group|
        group.with_avatar(src: '/avatar.png', size: :xs)
      end

      expect(page).to have_css '.avatar .w-8'
      expect(page).not_to have_css '.avatar .w-24'
    end
  end

  describe 'options passthrough' do
    it 'passes extra options to container' do
      render_inline(described_class.new(data: { testid: 'avatar-group' },
                                        id: 'my-group')) do |group|
        group.with_avatar(src: '/avatar.png', size: :sm)
      end

      expect(page).to have_css '.avatar-group[data-testid="avatar-group"][id="my-group"]'
    end
  end
end

RSpec.describe Bali::Avatar::Picture::Component, type: :component do
  it 'renders image with object-cover class' do
    render_inline(described_class.new(image_url: '/avatar.png'))

    expect(page).to have_css 'img.object-cover[src*="avatar.png"]'
  end

  it 'accepts additional options' do
    render_inline(described_class.new(image_url: '/avatar.png', alt: 'User avatar',
                                      class: 'custom'))

    expect(page).to have_css 'img[alt="User avatar"]'
    expect(page).to have_css 'img.custom'
  end

  it 'does not add avatar-target data attribute by default' do
    render_inline(described_class.new(image_url: '/avatar.png'))

    expect(page).not_to have_css 'img[data-avatar-target]'
  end

  it 'accepts data attributes when passed' do
    render_inline(described_class.new(image_url: '/avatar.png', data: { avatar_target: 'output' }))

    expect(page).to have_css 'img[data-avatar-target="output"]'
  end
end
