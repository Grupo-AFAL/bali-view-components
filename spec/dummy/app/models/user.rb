# frozen_string_literal: true

# Owner mínimo para las vistas guardadas (Bali::SavedView#owner es polimórfico; el default
# del engine resuelve current_user en el host).
class User < ApplicationRecord
end
