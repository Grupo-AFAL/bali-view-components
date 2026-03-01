# frozen_string_literal: true

module Admin
  class SettingsController < BaseController
    def show
      @settings = SettingsForm.new(
        dark_mode: session[:dark_mode] || false,
        language: session[:language] || 'en',
        timezone: session[:timezone] || 'UTC',
        email_notifications: session[:email_notifications].nil? || session[:email_notifications],
        push_notifications: session[:push_notifications] || false,
        notification_frequency: session[:notification_frequency] || 'daily',
        profile_visible: session[:profile_visible].nil? || session[:profile_visible],
        show_activity: session[:show_activity].nil? || session[:show_activity]
      )
    end

    def update
      settings_params.each { |key, value| session[key] = value }
      redirect_to admin_settings_path, notice: 'Settings saved successfully!'
    end

    private

    def settings_params
      params.permit(
        :dark_mode, :language, :timezone,
        :email_notifications, :push_notifications, :notification_frequency,
        :profile_visible, :show_activity
      )
    end
  end
end
