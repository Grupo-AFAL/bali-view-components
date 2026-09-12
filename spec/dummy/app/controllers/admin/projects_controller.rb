# frozen_string_literal: true

module Admin
  class ProjectsController < BaseController
    def index
      @projects = Project.all.order(:name)
    end

    def show
      @project = Project.find(params[:id])
      @view = params[:view] == 'timeline' ? 'timeline' : 'board'
      @tasks_by_status = @project.tasks_by_status
      @gantt = ProjectGantt.new(@project) if @view == 'timeline'
    end
  end
end
