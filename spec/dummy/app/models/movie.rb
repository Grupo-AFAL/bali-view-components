# frozen_string_literal: true

class Movie < ApplicationRecord
  belongs_to :studio, class_name: "Tenant", foreign_key: "tenant_id"
  alias_method :tenant, :studio

  has_many :characters, dependent: :destroy

  # Active Storage attachment for DirectUpload demo
  has_one_attached :poster

  accepts_nested_attributes_for :characters, allow_destroy: true

  GENRES = %w[Action Adventure Animation Comedy Crime Documentary Drama Fantasy Horror Musical Romance Sci-Fi Thriller Western].freeze

  enum :status, { draft: 0, done: 1 }

  # The reference form needs one reachable field-level error. The synopsis is the
  # field there that carries help text and a character counter and is not marked
  # `required`, so an over-long value shows an error next to its help without the
  # browser blocking the submit first.
  validates :synopsis, length: { maximum: 500 }

  # Virtual attributes (not persisted)
  attribute :duration, default: -> { "#{Date.current} 00:00:00" }
  attribute :cover_photo
  attribute :available_region

  # Un `ransacker` es la única forma de meter una expresión SQL en el panel avanzado —un
  # `ransackable_scope` no cabe ahí— y desde #1102 también AGRUPA, no solo ordena: el
  # `GROUP BY` sale de este mismo Arel. `#budget_band` es su gemelo en Ruby, el que lee la
  # banda de UNA fila; los dos tienen que devolver las mismas etiquetas o el conteo global
  # del encabezado no se encuentra.
  BUDGET_BANDS = { "blockbuster" => 50_000_000, "mid" => 5_000_000 }.freeze

  ransacker :budget_band do |parent|
    Arel::Nodes::Case.new
      .when(parent.table[:budget].gteq(BUDGET_BANDS["blockbuster"])).then("blockbuster")
      .when(parent.table[:budget].gteq(BUDGET_BANDS["mid"])).then("mid")
      .else("indie")
  end

  scope :budgeted, -> { where(budget: 1..) }
  scope :indie, -> { where(indie: true) }
  scope :top_rated, ->(limit: 5) { includes(:studio).order(rating: :desc).limit(limit) }

  def self.by_genre_count = group(:genre).count
  def self.by_status_count = group(:status).count.transform_keys(&:humanize)

  def self.average_rating
    where.not(rating: nil).average(:rating)&.round(1) || 0
  end

  def self.completion_rate
    total = count
    return 0 if total.zero?

    (done.count * 100.0 / total).round
  end

  def self.ratings_by_genre
    where.not(rating: nil).group(:genre).average(:rating).transform_values { |v| v.round(1) }
  end

  def self.budget_by_genre
    budgeted.group(:genre).sum(:budget)
  end

  def self.budget_by_status
    budgeted
      .group(:status)
      .sum(:budget)
      .transform_keys(&:humanize)
  end

  def status_color
    done? ? :success : :warning
  end

  # El gemelo en Ruby del ransacker `budget_band`: mismo umbral, mismas etiquetas. Un budget
  # nulo cae en "indie" del lado de SQL (`NULL >= x` es NULL, así que gana el ELSE) y tiene
  # que caer ahí también acá.
  def budget_band
    return "indie" if budget.blank?

    BUDGET_BANDS.find { |_band, floor| budget >= floor }&.first || "indie"
  end

  def reorder_characters(ordered_ids)
    transaction do
      ordered_ids.each_with_index do |id, index|
        characters.where(id: id).update_all(position: index)
      end
    end
  end
end
