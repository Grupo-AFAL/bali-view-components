# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Stepper::Component, type: :component do
  let(:options) { { current: 0 } }
  let(:component) { Bali::Stepper::Component.new(**options) }

  subject { rendered_component }

  it 'renders stepper with first step current' do
    render_inline(component) do |c|
      c.step(title: 'Step One')
      c.step(title: 'Step Two')
      c.step(title: 'Step Three')
    end

    expect(subject).to have_css 'div.stepper-component'
    expect(subject).to have_css '.step-component.is-active', text: 'Step One'
    expect(subject).to have_css '.step-component.is-pending', text: 'Step Two'
    expect(subject).to have_css '.step-component.is-pending', text: 'Step Three'
  end

  it 'renders stepper with second step current' do
    options[:current] = 1

    render_inline(component) do |c|
      c.step(title: 'Step One')
      c.step(title: 'Step Two')
      c.step(title: 'Step Three')
    end

    expect(subject).to have_css 'div.stepper-component'
    expect(subject).to have_css '.step-component.is-done', text: 'Step One'
    expect(subject).to have_css '.step-component.is-active', text: 'Step Two'
    expect(subject).to have_css '.step-component.is-pending', text: 'Step Three'
  end

  it 'renders stepper with third step current' do
    options[:current] = 2

    render_inline(component) do |c|
      c.step(title: 'Step One')
      c.step(title: 'Step Two')
      c.step(title: 'Step Three')
    end

    expect(subject).to have_css 'div.stepper-component'
    expect(subject).to have_css '.step-component.is-done', text: 'Step One'
    expect(subject).to have_css '.step-component.is-done', text: 'Step Two'
    expect(subject).to have_css '.step-component.is-active', text: 'Step Three'
  end
end
