# frozen_string_literal: true

# Minimal owner for the saved views (Bali::SavedView#owner is polymorphic; the engine's
# default resolves current_user in the host).
class User < ApplicationRecord
  DEMO_NAME = 'Ana García'

  # The dummy does not authenticate: `SessionsController#create` only redirects with "Demo app
  # — no real authentication configured". Saved views DO need an owner, so there is exactly one
  # and it is the same one the topbar names. `find_or_create_by!` and not `first` because the
  # engine's controller resolves it in requests that can arrive before the seeds.
  def self.demo
    find_or_create_by!(name: DEMO_NAME)
  end
end
