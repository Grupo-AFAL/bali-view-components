# frozen_string_literal: true

require 'rails_helper'

class CustomApplitationController < ApplicationController
  include Bali::LayoutConcern
end

RSpec.describe 'Bali::LayoutConcern' do
  let(:controller) { CustomApplitationController.new }

  describe '#conditionally_skip_layout' do
    it 'returns false if layout param is false' do
      controller.params = { layout: 'false' }
      expect(controller.conditionally_skip_layout).to be false
    end

    it 'returns controller conditional_layout if layout param is true' do
      controller.params = { layout: 'true' }
      controller.class.conditional_layout = 'my_layout'

      expect(controller.conditionally_skip_layout).to eql('my_layout')
    end
  end
end
