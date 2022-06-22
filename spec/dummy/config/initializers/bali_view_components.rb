# frozen_string_literal: true

ActiveSupport.on_load :active_record do
  include Bali::Types
end
