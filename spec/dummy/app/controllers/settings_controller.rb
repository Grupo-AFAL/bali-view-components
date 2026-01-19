# frozen_string_literal: true

class SettingsController < ApplicationController
  def show
    # Use SettingsForm (ActiveModel::Model) for Bali::FormBuilder compatibility
    @settings = SettingsForm.new(
      dark_mode: session[:dark_mode] || false,
      language: session[:language] || 'en',
      timezone: session[:timezone] || 'UTC',
      email_notifications: session[:email_notifications].nil? ? true : session[:email_notifications],
      push_notifications: session[:push_notifications] || false,
      notification_frequency: session[:notification_frequency] || 'daily',
      profile_visible: session[:profile_visible].nil? ? true : session[:profile_visible],
      show_activity: session[:show_activity].nil? ? true : session[:show_activity]
    )
  end

  def update
    # Store settings in session
    settings_params.each do |key, value|
      session[key] = value
    end

    redirect_to settings_path, notice: 'Settings saved successfully!'
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
