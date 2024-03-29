# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::Avatar::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Avatar::Component.new(**options) }
  let(:helper) { FormHelperTest.new(nil) }

  it 'renders the avatar component' do
    helper.form_with(url: '/') do |form|
      options.merge!(method: :test, form: form, placeholder_url: '/bulma-default.png')
      render_inline(component)
    end

    expect(page).to have_css '.avatar-component > figure.image'
    expect(page).to have_css '.avatar-component > .icon-content'
    expect(page).to have_css 'figure.image > img.is-rounded'
    expect(page).to have_css '.icon-content > label > .control'
    expect(page).to have_css '.icon-content > label > .icon-component.icon'
    expect(page).to have_css '.control > input[accept=".jpg, .jpeg, .png,"]'
    expect(page).to have_css '.control > input[name="test"]'
  end

  it 'renders the avatar component with an image loaded' do
    helper.form_with(url: '/') do |form|
      options.merge!(method: :test, form: form, placeholder_url: '/bulma-default.png')
      render_inline(component) do |c|
        c.with_picture(image_url: '/avatar.png', class: 'test-image')
      end
    end

    expect(page).to have_css '.avatar-component > figure.image'
    expect(page).to have_css 'figure.image > img[src*="avatar.png"]'
  end
end
