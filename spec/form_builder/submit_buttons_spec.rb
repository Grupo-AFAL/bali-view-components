# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#submit' do
    it 'renders an input' do
      expect(builder.submit('Save')).to include(
        '<div class="inline">'\
        '<button type="submit" class="button is-primary">Save</button>'\
        '</div>'
      )
    end
  end

  describe '#submit_actions' do
    it 'renders an input' do
      expect(
        builder.submit_actions('Save', cancel_path: '/', cancel_options: { label: 'Back' })
      ).to include(
        '<div class="field is-grouped is-grouped-right">'\
        '<div class="control">'\
        '<a class="button is-secondary" href="/">Back</a>'\
        '</div><div class="control">'\
        '<div class="inline">'\
        '<button type="submit" class="button is-primary">Save</button>'\
        '</div></div></div>'
      )
    end
  end
end
