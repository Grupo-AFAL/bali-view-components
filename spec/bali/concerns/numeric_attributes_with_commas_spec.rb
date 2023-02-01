# frozen_string_literal: true

require 'rails_helper'

class ModelWithNumericAttributesWithCommas
  include Bali::Concerns::NumericAttributesWithCommas

  currency_attribute :price
  percentage_attribute :waste_percentage
end

RSpec.describe Bali::Concerns::NumericAttributesWithCommas do
  let(:model) { ModelWithNumericAttributesWithCommas.new }

  describe '#price' do
    before { model.price = 10 }

    it { expect(model.price).to eq(10) }
  end

  describe '#price=' do
    context 'with integer' do
      before { model.price = 10 }

      it { expect(model.price).to eq(10) }
    end

    context 'with decimal' do
      before { model.price = 10.0 }

      it { expect(model.price).to eq(10.0) }
    end

    context 'with integer as string' do
      before { model.price = '10' }

      it { expect(model.price).to eq(10) }
    end

    context 'with decimal as string' do
      before { model.price = '10.0' }

      it { expect(model.price).to eq(10.0) }
    end

    context 'with decimal as string using "," as delimiter' do
      before { model.price = '1,000.50' }

      it { expect(model.price).to eq(1000.5) }
    end
  end
end
