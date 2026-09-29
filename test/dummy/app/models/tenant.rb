# frozen_string_literal: true

class Tenant < ApplicationRecord
  include Bali::Concerns::SoftDelete

  # rubocop: disable Rails/HasManyOrHasOneDependent
  has_many :movies
  # rubocop: enable Rails/HasManyOrHasOneDependent
end
