# frozen_string_literal: true

class EntityReferencesController < ApplicationController
  ENTITIES = [
    { entityType: 'task', entityId: '1', entityName: 'Fix authentication bug' },
    { entityType: 'task', entityId: '2', entityName: 'Add pagination to users list' },
    { entityType: 'task', entityId: '3', entityName: 'Fix login bug' },
    { entityType: 'task', entityId: '4', entityName: 'Update API documentation' },
    { entityType: 'task', entityId: '5', entityName: 'Refactor payment processor' },
    { entityType: 'project', entityId: '1', entityName: 'Q4 Release' },
    { entityType: 'project', entityId: '2', entityName: 'Mobile App Redesign' },
    { entityType: 'project', entityId: '3', entityName: 'Infrastructure Migration' },
    { entityType: 'document', entityId: '1', entityName: 'Architecture Decision Record' },
    { entityType: 'document', entityId: '2', entityName: 'Onboarding Guide' },
    { entityType: 'document', entityId: '3', entityName: 'API Specification' }
  ].freeze

  URLS = {
    'task' => '/tasks',
    'project' => '/projects',
    'document' => '/documents'
  }.freeze

  # GET /entity_references?q=fix&types[]=task
  def index
    results = ENTITIES

    if params[:types].present?
      types = Array(params[:types])
      results = results.select { |e| types.include?(e[:entityType]) }
    end

    if params[:q].present?
      query = params[:q].downcase
      results = results.select { |e| e[:entityName].downcase.include?(query) }
    end

    render json: results
  end

  # POST /entity_references/resolve
  # Body: { refs: [{ entityType: 'task', entityId: '1' }, ...] }
  def resolve
    refs = Array(params[:refs])
    resolved = refs.filter_map do |ref|
      entity = ENTITIES.find do |e|
        e[:entityType] == ref[:entityType] && e[:entityId] == ref[:entityId]
      end
      next unless entity

      entity.merge(url: "#{URLS[entity[:entityType]]}/#{entity[:entityId]}")
    end

    render json: resolved
  end
end
