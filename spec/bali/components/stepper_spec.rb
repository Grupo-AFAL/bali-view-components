# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Stepper::Component, type: :component do
  let(:options) { { current: 0 } }
  let(:component) { Bali::Stepper::Component.new(**options) }

  it 'renders stepper with first step current' do
    render_inline(component) do |c|
      c.with_step(title: 'Step One')
      c.with_step(title: 'Step Two')
      c.with_step(title: 'Step Three')
    end

    expect(page).to have_css 'div.stepper-component'
    expect(page).to have_css '.step-component.is-active', text: 'Step One'
    expect(page).to have_css '.step-component.is-pending', text: 'Step Two'
    expect(page).to have_css '.step-component.is-pending', text: 'Step Three'
  end

  it 'renders stepper with second step current' do
    options[:current] = 1

    render_inline(component) do |c|
      c.with_step(title: 'Step One')
      c.with_step(title: 'Step Two')
      c.with_step(title: 'Step Three')
    end

    expect(page).to have_css 'div.stepper-component'
    expect(page).to have_css '.step-component.is-done', text: 'Step One'
    expect(page).to have_css '.step-component.is-active', text: 'Step Two'
    expect(page).to have_css '.step-component.is-pending', text: 'Step Three'
  end

  it 'renders stepper with third step current' do
    options[:current] = 2

    render_inline(component) do |c|
      c.with_step(title: 'Step One')
      c.with_step(title: 'Step Two')
      c.with_step(title: 'Step Three')
    end

    expect(page).to have_css 'div.stepper-component'
    expect(page).to have_css '.step-component.is-done', text: 'Step One'
    expect(page).to have_css '.step-component.is-done', text: 'Step Two'
    expect(page).to have_css '.step-component.is-active', text: 'Step Three'
  end
end
