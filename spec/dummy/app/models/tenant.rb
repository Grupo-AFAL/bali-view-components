# frozen_string_literal: true

class Tenant < ApplicationRecord
  include Bali::Concerns::SoftDelete

  has_many :movies
end
