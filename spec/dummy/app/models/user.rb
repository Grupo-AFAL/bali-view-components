# frozen_string_literal: true

# Owner mínimo para las vistas guardadas (Bali::SavedView#owner es polimórfico; el default
# del engine resuelve current_user en el host).
class User < ApplicationRecord
  DEMO_NAME = 'Ana García'

  # El dummy no autentica: `SessionsController#create` solo redirige con "Demo app — no real
  # authentication configured". Las vistas guardadas SÍ necesitan un dueño, así que hay uno
  # solo y es el mismo que nombra el topbar. `find_or_create_by!` y no `first` porque el
  # controller del engine lo resuelve en requests que pueden llegar antes de los seeds.
  def self.demo
    find_or_create_by!(name: DEMO_NAME)
  end
end
