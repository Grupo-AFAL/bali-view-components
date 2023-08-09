# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FieldGroupWrapper::Component, type: :component do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil) }
  let(:resource) { Movie.new }
  let(:builder) { Bali::FormBuilder.new :movie, resource, helper, {} }

  let(:component) { Bali::FieldGroupWrapper::Component.new(builder, :name, @options) }

  before { @options = {} }

  context 'default' do
    it 'renders field with label' do
      render_inline(component)

      expect(page).to have_css '#field-name.field'
      expect(page).to have_css 'label.label', text: 'Name'
    end
  end
end
