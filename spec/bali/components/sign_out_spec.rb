# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::TurboNativeApp::SignOut::Component, type: :component do
  let(:component) { Bali::TurboNativeApp::SignOut::Component.new(**@options) }

  before { @options = {} }

  describe '#render' do
    context 'default' do
      it 'renders' do
        render_inline(component)
    
        expect(page).to have_css 'button.turbo-native-app-sign-out-component', text: 'Sign out'
        expect(page).to have_css '[data-controller="turbo-native-app-sign-out"]'
        expect(page).to have_css '[data-action="turbo-native-app-sign-out#perform"]'
        expect(page).to have_css(
          '[data-turbo-native-app-sign-out-confirmation-message-value='\
          '"Are you sure?"]'
        )
      end  
    end

    context 'with custom name' do
      before { @options.merge!(name: 'Log out') }

      it 'renders' do
        render_inline(component)
    
        expect(page).to have_css 'button.turbo-native-app-sign-out-component', text: 'Log out'
        expect(page).to have_css '[data-controller="turbo-native-app-sign-out"]'
        expect(page).to have_css '[data-action="turbo-native-app-sign-out#perform"]'
        expect(page).to have_css(
          '[data-turbo-native-app-sign-out-confirmation-message-value='\
          '"Are you sure?"]'
        )
      end  
    end

    context 'with custom confirmation message' do
      before { @options.merge!(confirm: 'are u sure?') }

      it 'renders' do
        render_inline(component)
    
        expect(page).to have_css 'button.turbo-native-app-sign-out-component', text: 'Sign out'
        expect(page).to have_css '[data-controller="turbo-native-app-sign-out"]'
        expect(page).to have_css '[data-action="turbo-native-app-sign-out#perform"]'
        expect(page).to have_css(
          '[data-turbo-native-app-sign-out-confirmation-message-value='\
          '"are u sure?"]'
        )
      end  
    end
  end
end
