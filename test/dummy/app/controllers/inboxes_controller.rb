# frozen_string_literal: true

# The reference host controller `docs/guides/engine-models.md` («Inbox and notices») describes:
# the concern brings every action and the views; the owner comes from ApplicationController's
# InboxBadge, which is `current_user`.
class InboxesController < ApplicationController
  include Bali::Concerns::Controllers::Inbox

  # The admin shell, so the page sits under the topbar whose icon opens it.
  self.conditional_layout = "admin"
end
