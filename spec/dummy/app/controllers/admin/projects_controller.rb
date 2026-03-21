# frozen_string_literal: true

module Admin
  class ProjectsController < BaseController
    def index
      @projects = Project.all.order(:name)
    end

    def show
      @project = Project.find(params[:id])
      @tasks_by_status = @project.tasks_by_status
    end
  end
end
