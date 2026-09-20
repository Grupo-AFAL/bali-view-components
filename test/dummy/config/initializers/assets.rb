# frozen_string_literal: true

# Configure Propshaft to find Bali's JavaScript assets
Rails.application.config.assets.paths << Rails.root.join("../../app/assets/javascripts")
Rails.application.config.assets.paths << Rails.root.join("../../app/components")
