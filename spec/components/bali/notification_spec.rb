# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Notification::Component, type: :component do
  let(:component) { described_class }

  subject { rendered_component }

  context 'default' do
    it 'renders success component with default values' do
      render_inline(component.new) do
        'Hello World!'
      end

      is_expected.to have_css 'div.notification', text: 'Hello World!'
      is_expected.to have_css 'div.is-success'
    end
  end

  %i[success info warning danger].each do |notification_type|
    context "#{notification_type} notification type" do
      it 'renders' do
        render_inline(component.new(type: notification_type)) do
          'Hello World!'
        end

        is_expected.to have_css 'div.notification', text: 'Hello World!'
        is_expected.to have_css "div.is-#{notification_type}"
      end
    end
  end
end
