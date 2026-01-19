# frozen_string_literal: true

# Form object for Settings page - demonstrates using ActiveModel::Model
# with Bali::FormBuilder for non-database backed forms
class SettingsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :dark_mode, :boolean, default: false
  attribute :language, :string, default: 'en'
  attribute :timezone, :string, default: 'UTC'
  attribute :email_notifications, :boolean, default: true
  attribute :push_notifications, :boolean, default: false
  attribute :notification_frequency, :string, default: 'daily'
  attribute :profile_visible, :boolean, default: true
  attribute :show_activity, :boolean, default: true

  def model_name
    ActiveModel::Name.new(self.class, nil, 'Settings')
  end
end
