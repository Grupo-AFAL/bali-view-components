# frozen_string_literal: true

module Bali
  module Concerns
    module Controllers
      module DeviceVariants
        extend ActiveSupport::Concern

        included do
          before_action do
            request.variant = :native_app if native_app?
            request.variant = :mobile if mobile?
          end

          before_action do
            Bali.native_app = native_app?
          end

          delegate :device_type, to: :device_detector
        end

        def bot?
          device_detector.bot? || empty_device_info? || sketchy_username?
        end

        def mobile?
          device_detector.device_type == 'smartphone'
        end

        def tablet?
          %w[tablet phablet].include?(device_detector.device_type)
        end

        def desktop?
          device_detector.device_type == 'desktop'
        end

        def empty_device_info?
          device_detector.device_type.nil? && device_detector.os_name.nil?
        end

        def sketchy_username?
          sketcky_usernames.include?(params.dig(:user, :email))
        end

        def native_app?
          ios_app? || android_app?
        end

        def ios_app?
          request.user_agent.to_s.match?(Bali.ios_native_app_user_agent)
        end

        def android_app?
          request.user_agent.to_s.match?(Bali.android_native_app_user_agent)
        end

        private

        def sketcky_usernames
          %w[admin cnadmin enjoykitchen cnenjoykitchen cnenjoykitchen.mx]
        end

        def device_detector
          @device_detector ||= DeviceDetector.new(request.user_agent)
        end
      end
    end
  end
end
