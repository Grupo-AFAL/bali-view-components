# frozen_string_literal: true

class MoviesController < ApplicationController
  def index
    @q = Movie.ransack(search_params)
    @movies = @q.result.includes(:tenant).limit(50)

    # FilterForm requires scope and params
    @filter_form = Bali::FilterForm.new(Movie.all, params)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def search_params
    # Ransack groupings (g) are deeply nested, so we need to permit them carefully
    # The format is: q[g][0][field_operator]=value, q[g][0][m]=or/and
    params.fetch(:q, {}).to_unsafe_h
  end

  # Define filterable attributes for the advanced filters
  helper_method :available_filter_attributes
  def available_filter_attributes
    genres = Movie.distinct.pluck(:genre).compact.sort.map { |g| [g, g] }
    studios = Tenant.order(:name).pluck(:name, :id)

    [
      { key: :name, label: 'Name', type: :text },
      {
        key: :genre,
        label: 'Genre',
        type: :select,
        options: genres
      },
      {
        key: :tenant_id,
        label: 'Studio',
        type: :select,
        options: studios
      },
      {
        key: :status,
        label: 'Status',
        type: :select,
        options: Movie.statuses.map { |k, _v| [k.humanize, k] }
      },
      { key: :created_at, label: 'Created Date', type: :date },
      { key: :indie, label: 'Indie Film', type: :boolean }
    ]
  end

  # Get the combinator between filter groups from params (q[m])
  helper_method :group_combinator_from_params
  def group_combinator_from_params
    params.dig(:q, :m) || 'and'
  end

  # Get the quick search value from params
  helper_method :quick_search_value
  def quick_search_value
    params.dig(:q, :name_or_genre_cont)
  end

  # Parse filter groups from URL params for advanced filters
  helper_method :filter_groups_from_params
  def filter_groups_from_params
    # Advanced filters use q[g][0][field_operator]=value format
    # Parse these back into filter groups structure
    groups = params.dig(:q, :g)
    return [] unless groups.is_a?(ActionController::Parameters)

    groups.values.map do |group_params|
      conditions = group_params.to_unsafe_h.map do |key, value|
        next if key == 'm' # Skip the combinator/match mode param

        # Parse "field_operator" format
        operators = 'eq|cont|gt|lt|gteq|lteq|in|not_eq|not_cont|not_in|start|end'
        match = key.to_s.match(/^(.+)_(#{operators})$/)
        next unless match

        {
          attribute: match[1],
          operator: match[2],
          value: value
        }
      end.compact

      {
        combinator: group_params[:m] || 'or',
        conditions: conditions.presence || [{ attribute: '', operator: 'cont', value: '' }]
      }
    end
  end
end
