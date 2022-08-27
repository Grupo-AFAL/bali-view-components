# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Types::MonthValue do
  describe 'integration with a model' do
    it 'casts a month value from month string to a date value' do
      character = Character.new(birth_month: '2022-08')
      expect(character.birth_month).to eql(Date.parse('2022-08-01'))
    end
  end

  subject { Bali::Types::MonthValue.new }

  describe '#cast' do
    it 'return a nil if value is blank' do
      expect(subject.cast('')).to be_nil
    end

    it 'returns a date object' do
      expect(subject.cast('2022-08')).to eql(Date.parse('2022-08-01'))
    end
  end

  describe 'serialize' do
    it 'returns value if is blank' do
      expect(subject.serialize('')).to eql('')
    end

    it 'returns a normalized date' do
      expect(subject.serialize('2022-08')).to eql('2022-08-01')
    end
  end
end
