# frozen_string_literal: true

class MoviesController < ApplicationController
  include Pagy::Backend

  def index
    # FilterForm handles Ransack search params and sorting
    @filter_form = Bali::FilterForm.new(Movie.all, params)

    # Use Pagy for pagination on the filtered/sorted results
    @pagy, @movies = pagy(@filter_form.result.includes(:tenant), items: 10)

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
      raw_conditions = {}
      group_params.to_unsafe_h.each do |key, value|
        next if key == 'm' # Skip the combinator/match mode param

        # Parse "field_operator" format
        operators = 'eq|cont|gt|lt|gteq|lteq|in|not_eq|not_cont|not_in|start|end'
        match = key.to_s.match(/^(.+)_(#{operators})$/)
        next unless match

        attribute = match[1]
        operator = match[2]

        # Collect gteq/lteq pairs for potential "between" consolidation
        raw_conditions[attribute] ||= {}
        raw_conditions[attribute][operator] = value
      end

      # Convert raw conditions to final format, combining gteq+lteq into "between"
      conditions = raw_conditions.flat_map do |attribute, ops|
        if ops['gteq'] && ops['lteq']
          # Combine into a single "between" condition
          [{
            attribute: attribute,
            operator: 'between',
            value: { start: ops['gteq'], end: ops['lteq'] }
          }]
        else
          # Keep as separate conditions
          ops.map do |operator, value|
            { attribute: attribute, operator: operator, value: value }
          end
        end
      end

      {
        combinator: group_params[:m] || 'or',
        conditions: conditions.presence || [{ attribute: '', operator: 'cont', value: '' }]
      }
    end
  end
end
