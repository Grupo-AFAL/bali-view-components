# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bali::Card::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Card::Component.new(**options) }

  subject { rendered_component }

  it "renders" do
    render_inline(component)

    is_expected.to have_css "div"
  end
end