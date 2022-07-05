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
      options.merge!(method: :test, form: form)
      render_inline(component)
    end

    expect(rendered_component).to have_css '.avatar-component > figure.image'
    expect(rendered_component).to have_css '.avatar-component > .icon-content'
    expect(rendered_component).to have_css 'figure.image > img.is-rounded'
    expect(rendered_component).to have_css '.icon-content > label > .control'
    expect(rendered_component).to have_css '.icon-content > label > .icon-component.icon'
    expect(rendered_component).to have_css '.control > input[accept=".jpg, .jpeg, .png,"]'
    expect(rendered_component).to have_css '.control > input[name="test"]'
  end
end
