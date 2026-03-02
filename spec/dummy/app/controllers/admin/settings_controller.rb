# frozen_string_literal: true

module Admin
  class SettingsController < BaseController
    def show
      @settings = SettingsForm.new(stored_settings)
    end

    def update
      session[:settings] = stored_settings.merge(settings_params.to_h.symbolize_keys)
      redirect_to admin_settings_path, notice: 'Settings saved successfully!'
    end

    private

    def stored_settings
      (session[:settings] || {}).symbolize_keys.reverse_merge(SettingsForm.defaults)
    end

    def settings_params
      params.permit(
        :dark_mode, :language, :timezone,
        :email_notifications, :push_notifications, :notification_frequency,
        :profile_visible, :show_activity
      )
    end
  end
end
