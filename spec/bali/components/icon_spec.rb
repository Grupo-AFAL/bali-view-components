# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Icon::Component, type: :component do
  let(:component) { Bali::Icon::Component.new('snowflake', **@options) }

  before { @options = {} }

  subject { page }

  it 'renders' do
    render_inline(component)

    is_expected.to have_css 'span.icon'
  end

  it 'renders with an id and additional classes' do
    @options.merge!(id: 'my-icon', class: 'has-text-info')
    render_inline(component)

    is_expected.to have_css 'span.icon.has-text-info'
    is_expected.to have_css 'span[id="my-icon"]'
  end
end
