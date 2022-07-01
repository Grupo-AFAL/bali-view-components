# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SortableList::Component, type: :component do
  let(:options) { {  } }
  let(:component) { Bali::SortableList::Component.new(**options) }

  subject { rendered_component }

  it 'renders sortablelist component' do
    render_inline(component)

    expect(subject).to have_css 'div.sortable_list-component'
  end
end
