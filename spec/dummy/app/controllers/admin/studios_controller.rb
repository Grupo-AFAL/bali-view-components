# frozen_string_literal: true

module Admin
  class StudiosController < BaseController
    before_action :set_studio, only: %i[show edit update destroy]

    def index
      @filter_form = Bali::FilterForm.new(
        Studio.all,
        params,
        simple_filters: Studio.filter_options,
        search_fields: %i[name]
      )
      @pagy, @studios = pagy(@filter_form.result.order(:name), items: 10)
    end

    def show; end

    def new
      @studio = Studio.new
      render layout: !drawer_request?
    end

    def edit
      render layout: !drawer_request?
    end

    def create
      @studio = Studio.new(studio_params)
      if @studio.save
        redirect_to admin_studios_path, notice: 'Studio was successfully created.'
      else
        render :new, layout: !drawer_request?, status: :unprocessable_content
      end
    end

    def update
      if @studio.update(studio_params)
        redirect_to admin_studios_path, notice: 'Studio was successfully updated.'
      else
        render :edit, layout: !drawer_request?, status: :unprocessable_content
      end
    end

    def destroy
      @studio.destroy
      redirect_to admin_studios_url, notice: 'Studio was successfully deleted.'
    end

    private

    def set_studio
      @studio = Studio.find(params[:id])
    end

    def studio_params
      params.expect(studio: %i[name country status size founded_year])
    end
  end
end
