# frozen_string_literal: true

require 'rails_helper'

class TestHelperComponent
  include Bali::HtmlElementHelper
end

RSpec.describe Bali::HtmlElementHelper do
  let(:helper) { TestHelperComponent.new }

  describe '#prepend_action' do
    it 'adds a stimulus controller action' do
      options = helper.prepend_action({}, 'modal#open')
      expect(options[:data][:action]).to eq('modal#open')
    end
  end

  describe '#prepend_controller' do
    it 'adds a stimulus controller' do
      options = helper.prepend_controller({}, 'modal')
      expect(options[:data][:controller]).to eq('modal')
    end
  end

  describe '#prepend_values' do
    it 'adds values for a stimulus controller' do
      options = helper.prepend_values({}, 'list', { param_name: 'position' })

      expect(options[:data]['list-param-name-value']).to eq('position')
    end

    it 'does not override other values in data' do
      options = { data: { controller: 'list' } }
      options = helper.prepend_values(options, 'list', { param_name: 'position' })

      expect(options[:data][:controller]).to eq('list')
      expect(options[:data]['list-param-name-value']).to eq('position')
    end

    context 'when value is a Hash' do
      it 'adds values for a stimulus controller' do
        options = helper.prepend_values({}, 'list', { params: { name: 'position' } })

        expect(options[:data]['list-params-value']).to eq('{"name":"position"}')
      end
    end
  end

  describe '#prepend_class_name' do
    it 'adds a class to options hash' do
      options = helper.prepend_class_name({}, 'is-active')
      expect(options[:class]).to eq('is-active')
    end

    it 'prepends the class_name to the existing class' do
      options = helper.prepend_class_name({ class: 'list' }, 'is-active')
      expect(options[:class]).to eq('is-active list')
    end
  end
end
