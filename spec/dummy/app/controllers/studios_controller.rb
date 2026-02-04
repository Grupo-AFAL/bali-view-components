# frozen_string_literal: true

class StudiosController < ApplicationController
  # Pagy::Method is included in ApplicationController (Pagy 43+)
  before_action :set_studio, only: %i[show edit update destroy]

  def index
    @filter_form = Bali::FilterForm.new(
      Studio.all,
      params,
      simple_filters: simple_filters_config,
      search_fields: %i[name]
    )

    @pagy, @studios = pagy(@filter_form.result.order(:name), items: 10)
  end

  def show; end

  def new
    @studio = Studio.new
  end

  def edit; end

  def create
    @studio = Studio.new(studio_params)

    if @studio.save
      redirect_to @studio, notice: 'Studio was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @studio.update(studio_params)
      redirect_to @studio, notice: 'Studio was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @studio.destroy
    redirect_to studios_url, notice: 'Studio was successfully deleted.'
  end

  private

  def set_studio
    @studio = Studio.find(params[:id])
  end

  def studio_params
    params.expect(studio: %i[name country status size founded_year])
  end

  def simple_filters_config
    [
      {
        attribute: :country,
        collection: Studio::COUNTRIES.map { |c| [c, c] },
        blank: 'All Countries',
        label: 'Country'
      },
      {
        attribute: :status,
        collection: Studio.statuses.keys.map { |s| [s.humanize, s] },
        blank: 'All Statuses',
        label: 'Status'
      },
      {
        attribute: :size,
        collection: Studio::SIZES.map { |s| [s.humanize, s] },
        blank: 'All Sizes',
        label: 'Size'
      }
    ]
  end
end
