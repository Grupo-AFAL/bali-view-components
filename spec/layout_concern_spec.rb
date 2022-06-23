# frozen_string_literal: true

require 'rails_helper'

class CustomApplitationController < ApplicationController
  include Bali::LayoutConcern
end

RSpec.describe 'Bali::LayoutConcern' do
  let(:controller) { CustomApplitationController.new }

  describe '#conditionally_skip_layout' do
    context 'when layout param is false' do
      it 'returns false' do
        controller.params = { layout: 'false' }
        expect(controller.conditionally_skip_layout).to be false
      end
    end

    context 'when layout param is true' do
      it 'returns the controller conditional_layout' do
        controller.params = { layout: 'true' }
        controller.class.conditional_layout = 'my_layout'

        expect(controller.conditionally_skip_layout).to eql('my_layout')
      end
    end
  end
end
