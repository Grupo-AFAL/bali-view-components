# frozen_string_literal: true

require 'rails_helper'

class CustomHelperTest < ActionView::TestCase
  include Bali::Utils
end

RSpec.describe Bali::Utils do
  let(:helper) { CustomHelperTest.new(nil) }

  describe '#class_names' do
    context 'when names are given as string' do
      context 'conditional names are given' do
        it 'returns a string with the class names' do
          conditional_names = { 'is-centered' => false, 'is-primary' => true }

          expect(helper.class_names('is-active', conditional_names)).to eql('is-active is-primary')
        end
      end
    end

    context 'when names are given as a hash' do
      it 'returns a string with the class names' do
        names = { 'is-active' => true, 'is-centered' => false, 'is-primary' => true }

        expect(helper.class_names(names)).to eql('is-active is-primary')
      end
    end
  end

  describe '#custom_dom_id' do
    it 'returns a string with the dom id' do
      expect(helper.custom_dom_id(Movie.new)).to eql('movie_')
    end
  end

  describe '#test_id_attr' do
    context 'when params are given as string' do
      it 'returns a string with the test id' do
        expect(helper.test_id_attr('movie_1')).to eql('test-id="movie_1"')
      end
    end

    context 'when params are given as ActiveRecord' do
      it 'returns a string with the test id' do
        expect(helper.test_id_attr(Movie.new)).to eql('test-id="movie_"')
      end
    end

    context 'when no params are given' do
      it 'returns nil' do
        expect(helper.test_id_attr(nil)).to be_nil
      end
    end
  end
end
