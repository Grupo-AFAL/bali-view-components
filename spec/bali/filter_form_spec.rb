# frozen_string_literal: true

require 'rails_helper'

class MovieFilterForm < Bali::FilterForm
  attribute :name_i_cont, :string
  attribute :genre_in, default: []

  def scope
    @scope.active.order('UPPER(name) ASC')
  end
end

# Test form with filter_attribute DSL
class AdvancedMovieFilterForm < Bali::FilterForm
  filter_attribute :name, type: :text
  filter_attribute :genre, type: :select, options: [%w[Action action], %w[Comedy comedy]]
  filter_attribute :status, type: :select, label: 'Movie Status'
  filter_attribute :created_at, type: :date, label: 'Created Date'
  filter_attribute :indie, type: :boolean

  attribute :name_cont
  attribute :genre_eq
end

# Test inheritance
class ExtendedMovieFilterForm < AdvancedMovieFilterForm
  filter_attribute :rating, type: :number
end

# Test form with search_fields DSL
class SearchableMovieFilterForm < Bali::FilterForm
  search_fields :name, :genre, :tenant_name

  filter_attribute :name, type: :text
  filter_attribute :genre, type: :select, options: [%w[Action action], %w[Comedy comedy]]
end

RSpec.describe Bali::FilterForm do
  let(:tenant) { Tenant.create(name: 'Test') }
  let(:form) { MovieFilterForm.new(tenant.movies, params({ name_i_cont: 'Iron' })) }

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  before do
    @iron_man_3 = tenant.movies.create(name: 'Iron man 3', status: 1)
    @iron_man_2 = tenant.movies.create(name: 'Iron man 2', status: 0)
    @iron_man_1 = tenant.movies.create(name: 'Iron man 1', status: 0)
    @snatch = tenant.movies.create(name: 'Snatch', status: 0)
    @inglorious_basterds = tenant.movies.create(name: 'Inglorious Basterds', status: 0)
  end

  describe '#initialize' do
    it 'initializes a form with provided attributes' do
      expect(form.name_i_cont).to eql('Iron')
    end
  end

  describe '#permitted_attributes' do
    it 'returns an array of permitted attributes' do
      expect(form.permitted_attributes).to eql(
        ['s', 'name_i_cont', { 'genre_in' => [] }]
      )
    end
  end

  describe '#array_attributes' do
    it 'returns an array of array attributes' do
      expect(form.array_attributes).to eql(['genre_in'])
    end
  end

  describe '#active_filters_count' do
    it 'returns the number of active filters' do
      form = MovieFilterForm.new(tenant.movies, params({ genre_in: ['Action'] }))
      expect(form.active_filters_count).to eql(1)
    end
  end

  describe '#active_filters?' do
    it 'returns true with movie name filter' do
      form = MovieFilterForm.new(tenant.movies, params({ name_i_cont: 'Iron' }))
      expect(form.active_filters?).to be true
    end

    it 'returns true with movie genre filter' do
      form = MovieFilterForm.new(tenant.movies, params({ genre_in: ['Action'] }))
      expect(form.active_filters?).to be true
    end

    it 'returns false without any filters' do
      form = MovieFilterForm.new(tenant.movies, params({}))
      expect(form.active_filters?).to be false
    end
  end

  describe '#query_params' do
    it 'returns a hash of attributes and values' do
      expect(form.query_params).to eql(
        { 'genre_in' => nil, 'name_i_cont' => 'Iron', 's' => nil }
      )
    end
  end

  describe '#result' do
    let(:records) { form.result }

    it 'returns records matching the query and default scope' do
      expect(records.size).to eql(2)
      expect(records.map(&:name)).to include('Iron man 1', 'Iron man 2')
    end

    it 'orders results based on the scope order' do
      expect(records.first).to eql(@iron_man_1)
      expect(records.last).to eql(@iron_man_2)
    end
  end

  describe '.filter_attribute DSL' do
    it 'stores filter attributes defined in the class' do
      expect(AdvancedMovieFilterForm.filter_attributes.size).to eq(5)
    end

    it 'stores key, type, label, and options' do
      genre_attr = AdvancedMovieFilterForm.filter_attributes.find { |a| a[:key] == :genre }
      expect(genre_attr[:type]).to eq(:select)
      expect(genre_attr[:label]).to eq('Genre')
      expect(genre_attr[:options]).to eq([%w[Action action], %w[Comedy comedy]])
    end

    it 'uses humanized key as default label' do
      name_attr = AdvancedMovieFilterForm.filter_attributes.find { |a| a[:key] == :name }
      expect(name_attr[:label]).to eq('Name')
    end

    it 'allows custom labels' do
      status_attr = AdvancedMovieFilterForm.filter_attributes.find { |a| a[:key] == :status }
      expect(status_attr[:label]).to eq('Movie Status')
    end
  end

  describe '.filter_attribute inheritance' do
    it 'inherits filter_attributes from parent class' do
      expect(ExtendedMovieFilterForm.filter_attributes.size).to eq(6)
    end

    it 'includes parent attributes' do
      keys = ExtendedMovieFilterForm.filter_attributes.map { |a| a[:key] }
      expect(keys).to include(:name, :genre, :status, :created_at, :indie, :rating)
    end

    it 'does not modify parent class attributes' do
      expect(AdvancedMovieFilterForm.filter_attributes.size).to eq(5)
    end
  end

  describe '#available_attributes' do
    it 'returns the filter_attributes from the class' do
      form = AdvancedMovieFilterForm.new(Movie.all, params({}))
      expect(form.available_attributes).to eq(AdvancedMovieFilterForm.filter_attributes)
    end

    it 'returns empty array for forms without filter_attribute definitions' do
      form = MovieFilterForm.new(tenant.movies, params({}))
      expect(form.available_attributes).to eq([])
    end
  end

  describe '#filter_groups' do
    it 'returns empty array when no groupings present' do
      form = AdvancedMovieFilterForm.new(Movie.all, params({}))
      expect(form.filter_groups).to eq([])
    end

    it 'parses single filter group from params' do
      filter_params = {
        g: {
          '0' => {
            name_cont: 'Iron',
            m: 'or'
          }
        }
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      groups = form.filter_groups
      expect(groups.size).to eq(1)
      expect(groups[0][:combinator]).to eq('or')
      expect(groups[0][:conditions].size).to eq(1)
      expect(groups[0][:conditions][0]).to eq({
                                                attribute: 'name',
                                                operator: 'cont',
                                                value: 'Iron'
                                              })
    end

    it 'parses multiple conditions in a group' do
      filter_params = {
        g: {
          '0' => {
            name_cont: 'Iron',
            genre_eq: 'action',
            m: 'and'
          }
        }
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      conditions = form.filter_groups[0][:conditions]
      expect(conditions.size).to eq(2)
      expect(conditions.map { |c| c[:attribute] }).to contain_exactly('name', 'genre')
    end

    it 'consolidates gteq and lteq into between operator' do
      filter_params = {
        g: {
          '0' => {
            created_at_gteq: '2024-01-01',
            created_at_lteq: '2024-12-31'
          }
        }
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      conditions = form.filter_groups[0][:conditions]
      expect(conditions.size).to eq(1)
      expect(conditions[0][:operator]).to eq('between')
      expect(conditions[0][:value]).to eq({ start: '2024-01-01', end: '2024-12-31' })
    end

    it 'parses multiple filter groups' do
      filter_params = {
        g: {
          '0' => { name_cont: 'Iron', m: 'or' },
          '1' => { genre_eq: 'action', m: 'and' }
        },
        m: 'and'
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      expect(form.filter_groups.size).to eq(2)
    end
  end

  describe '#combinator' do
    it 'returns "and" as default' do
      form = AdvancedMovieFilterForm.new(Movie.all, params({}))
      expect(form.combinator).to eq('and')
    end

    it 'returns combinator from params' do
      filter_params = { m: 'or' }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
      expect(form.combinator).to eq('or')
    end
  end

  describe '#active_filter_details' do
    it 'returns empty array when no filters active' do
      form = AdvancedMovieFilterForm.new(Movie.all, params({}))
      expect(form.active_filter_details).to eq([])
    end

    it 'returns details for each active filter' do
      filter_params = {
        g: {
          '0' => {
            name_cont: 'Iron',
            genre_eq: 'action'
          }
        }
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      details = form.active_filter_details
      expect(details.size).to eq(2)
    end

    it 'includes attribute labels from filter_attribute definitions' do
      filter_params = {
        g: {
          '0' => { name_cont: 'Iron' }
        }
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      detail = form.active_filter_details.first
      expect(detail[:attribute_label]).to eq('Name')
    end

    it 'resolves select option labels for value_label' do
      filter_params = {
        g: {
          '0' => { genre_eq: 'action' }
        }
      }
      form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))

      detail = form.active_filter_details.first
      expect(detail[:value]).to eq('action')
      expect(detail[:value_label]).to eq('Action')
    end
  end

  describe '.search_fields DSL' do
    it 'stores search fields defined in the class' do
      expect(SearchableMovieFilterForm.defined_search_fields).to eq(%i[name genre tenant_name])
    end

    it 'returns search fields via instance method' do
      form = SearchableMovieFilterForm.new(Movie.all, params({}))
      expect(form.search_fields).to eq(%i[name genre tenant_name])
    end

    it 'returns empty array for forms without search_fields' do
      form = MovieFilterForm.new(tenant.movies, params({}))
      expect(form.search_fields).to eq([])
    end
  end

  describe '#search_enabled?' do
    it 'returns true when search_fields defined' do
      form = SearchableMovieFilterForm.new(Movie.all, params({}))
      expect(form.search_enabled?).to be true
    end

    it 'returns false when no search_fields' do
      form = MovieFilterForm.new(tenant.movies, params({}))
      expect(form.search_enabled?).to be false
    end
  end

  describe '#search_field_name' do
    it 'builds Ransack field name from search_fields' do
      form = SearchableMovieFilterForm.new(Movie.all, params({}))
      expect(form.search_field_name).to eq('name_or_genre_or_tenant_name_cont')
    end

    it 'returns nil when no search_fields' do
      form = MovieFilterForm.new(tenant.movies, params({}))
      expect(form.search_field_name).to be_nil
    end
  end

  describe '#search_value' do
    it 'extracts search value from params' do
      filter_params = { name_or_genre_or_tenant_name_cont: 'Iron' }
      form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))
      expect(form.search_value).to eq('Iron')
    end

    it 'returns nil when no search value in params' do
      form = SearchableMovieFilterForm.new(Movie.all, params({}))
      expect(form.search_value).to be_nil
    end
  end

  describe '#search_config' do
    it 'returns complete search configuration' do
      filter_params = { name_or_genre_or_tenant_name_cont: 'Iron' }
      form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))

      config = form.search_config
      expect(config[:fields]).to eq(%i[name genre tenant_name])
      expect(config[:value]).to eq('Iron')
      expect(config[:placeholder]).to eq('Search...')
    end

    it 'returns nil when search not enabled' do
      form = MovieFilterForm.new(tenant.movies, params({}))
      expect(form.search_config).to be_nil
    end
  end

  describe 'search_fields via initialize parameter' do
    it 'accepts search_fields as initialize parameter' do
      form = Bali::FilterForm.new(Movie.all, params({}), search_fields: %i[name description])
      expect(form.search_fields).to eq(%i[name description])
      expect(form.search_field_name).to eq('name_or_description_cont')
    end

    it 'extracts search value with dynamic search_fields' do
      filter_params = { name_or_description_cont: 'Test' }
      form = Bali::FilterForm.new(Movie.all, params(filter_params), search_fields: %i[name description])
      expect(form.search_value).to eq('Test')
    end

    it 'prefers instance search_fields over class DSL' do
      filter_params = { name_or_email_cont: 'test@example.com' }
      form = SearchableMovieFilterForm.new(Movie.all, params(filter_params), search_fields: %i[name email])

      expect(form.search_fields).to eq(%i[name email])
      expect(form.search_value).to eq('test@example.com')
    end
  end

  describe 'search integration with Ransack' do
    it 'includes search value in ransack_params' do
      filter_params = { name_or_genre_or_tenant_name_cont: 'Iron' }
      form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))

      # Access private method for testing
      ransack_params = form.send(:ransack_params)
      expect(ransack_params['name_or_genre_or_tenant_name_cont']).to eq('Iron')
    end

    it 'filters results using search value' do
      tenant = Tenant.create(name: 'Test Studio')
      tenant.movies.create(name: 'Iron Man', genre: 'Action')
      tenant.movies.create(name: 'Snatch', genre: 'Comedy')

      filter_params = { name_or_genre_cont: 'Iron' }
      form = Bali::FilterForm.new(Movie.all, params(filter_params), search_fields: %i[name genre])

      results = form.result
      expect(results.pluck(:name)).to include('Iron Man')
      expect(results.pluck(:name)).not_to include('Snatch')
    end
  end
end
