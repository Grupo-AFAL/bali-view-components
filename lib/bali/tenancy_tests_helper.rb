# frozen_string_literal: true

module Bali
  module TenancyTestsHelper
    def enable_tenancy
      raise MethodNotImplemented
    end

    def disable_tenancy
      raise MethodNotImplemented
    end

    def tenancy_configuration_for(models)
      enable_tenancy
      create_tenants_table

      models = Array(models)
      models.each do |model|
        add_tenant_id_to_table(model.table_name)
        reload_model(model)
      end

      add_tenant_id_to_unique_indexes(models)
      reset_factory_bot
    end

    def revert_tenancy_configuration_for(models)
      models = Array(models)

      disable_tenancy
      remove_tenant_id_to_unique_indexes(models)
      remove_tenants_table

      models.each do |model|
        remove_tenant_id_from_table(model.table_name)
        reload_model(model)
      end
      reset_factory_bot
    end

    private

    def migration
      return @migration if defined? @migration

      @migration = ActiveRecord::Migration.new
      @migration.verbose = false
      @migration
    end

    def create_tenants_table
      migration.create_table :tenants do |t|
        t.string :name
      end
    end

    def remove_tenants_table
      migration.drop_table :tenants
    end

    def add_tenant_id_to_table(table_name)
      migration.add_column table_name, :tenant_id, :integer
    end

    def remove_tenant_id_from_table(table_name)
      migration.remove_column table_name, :tenant_id, :integer
    end

    def reload_model(model)
      model.name.deconstantize.constantize.send(:remove_const, model.name.demodulize)
      load("app/models/#{model.name.underscore}.rb")
      model.reset_column_information if model.respond_to?(:reset_column_information)
    end

    def reset_factory_bot
      FactoryBot.factories.clear
      FactoryBot.find_definitions
      FactoryBot.reload
    end

    def add_tenant_id_to_unique_indexes(models); end

    def remove_tenant_id_to_unique_indexes(models); end
  end
end
