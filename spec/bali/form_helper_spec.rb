# frozen_string_literal: true

require 'rails_helper'

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

RSpec.describe Bali::FormHelper, type: :form_helper do
  let(:helper) { FormHelperTest.new(nil) }

  describe '#form_with' do
    it 'renders a form with submit-button controller' do
      expect(helper.form_with(url: '/',
                              method: 'post')).to have_css 'form[data-controller="submit-button"]'
    end
  end

  describe '#form_for' do
    it 'renders a form with submit-button controller' do
      expect(
        helper.form_for(Movie.new, url: '/') {}
      ).to have_css 'form[data-controller="submit-button"]'
    end
  end
end
