# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#switch_field_group' do
    it 'renders an input' do
      expect(builder.switch_field_group(:indie, label: 'Indie')).to include(
        '<p>Indie</p><div class="field switch">'
      )
    end
  end

  describe '#switch_field' do
    it 'renders an input' do
      expect(builder.switch_field(:indie)).to include(
        '<div class="field switch">'
      )
    end
  end
end
