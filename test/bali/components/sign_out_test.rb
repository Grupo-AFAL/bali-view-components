# frozen_string_literal: true

require "test_helper"

class Bali_TurboNativeApp_SignOut_ComponentTest < ComponentTestCase
  def test_render_default_renders
    render_inline(Bali::TurboNativeApp::SignOut::Component.new)
    assert_selector("button.turbo-native-app-sign-out-component", text: "Sign out")
    assert_selector('[data-controller="turbo-native-app-sign-out"]')
    assert_selector('[data-action="turbo-native-app-sign-out#perform"]')
    assert_selector(
      "[data-turbo-native-app-sign-out-confirmation-message-value=" \
      '"Are you sure?"]'
    )
  end

  def test_render_with_custom_name_renders
    render_inline(Bali::TurboNativeApp::SignOut::Component.new(name: "Log out"))
    assert_selector("button.turbo-native-app-sign-out-component", text: "Log out")
    assert_selector('[data-controller="turbo-native-app-sign-out"]')
    assert_selector('[data-action="turbo-native-app-sign-out#perform"]')
    assert_selector(
      "[data-turbo-native-app-sign-out-confirmation-message-value=" \
      '"Are you sure?"]'
    )
  end

  def test_render_with_custom_confirmation_message_renders
    render_inline(Bali::TurboNativeApp::SignOut::Component.new(confirm: "are u sure?"))
    assert_selector("button.turbo-native-app-sign-out-component", text: "Sign out")
    assert_selector('[data-controller="turbo-native-app-sign-out"]')
    assert_selector('[data-action="turbo-native-app-sign-out#perform"]')
    assert_selector('[data-turbo-native-app-sign-out-confirmation-message-value="are u sure?"]')
  end
end
