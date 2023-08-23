# frozen_string_literal: true

module Bali
  module Concerns
    module Mailers
      module UtmParams
        extend ActiveSupport::Concern

        included do
          helper_method :utm_params
        end

        def utm_params
          { utm_source: utm_source, utm_medium: utm_medium }
        end

        def utm_source
          "#{self.class.name.deconstantize} Mail"
        end

        def utm_medium
          "#{self.class.name} #{action_name.humanize.titlecase}".gsub(/::|(?<=[a-z])(?=[A-Z])/, ' ')
        end
      end
    end
  end
end
