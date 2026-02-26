# frozen_string_literal: true

require "test_helper"

class BaliConcernsSoftDeleteTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create(name: "Test")
    @soft_deleted_tenant = Tenant.create(name: "Test", deleted_at: Time.zone.now)
  end

  # active_and_deleted scope

  def test_active_and_deleted_includes_active_tenant
    assert_includes(Tenant.active_and_deleted, @tenant)
  end

  def test_active_and_deleted_includes_soft_deleted_tenant
    assert_includes(Tenant.active_and_deleted, @soft_deleted_tenant)
  end

  # active scope

  def test_active_includes_active_tenant
    assert_includes(Tenant.active, @tenant)
  end

  def test_active_excludes_soft_deleted_tenant
    refute_includes(Tenant.active, @soft_deleted_tenant)
  end

  # soft_deleted scope

  def test_soft_deleted_excludes_active_tenant
    refute_includes(Tenant.soft_deleted, @tenant)
  end

  def test_soft_deleted_includes_soft_deleted_tenant
    assert_includes(Tenant.soft_deleted, @soft_deleted_tenant)
  end

  # active?

  def test_active_tenant_is_active
    assert(@tenant.active?)
  end

  def test_soft_deleted_tenant_is_not_active
    refute(@soft_deleted_tenant.active?)
  end

  # soft_deleted?

  def test_active_tenant_is_not_soft_deleted
    refute(@tenant.soft_deleted?)
  end

  def test_soft_deleted_tenant_is_soft_deleted
    assert(@soft_deleted_tenant.soft_deleted?)
  end

  # soft_delete

  def test_soft_delete_sets_deleted_at
    assert_nil(@tenant.deleted_at)
    @tenant.soft_delete
    @tenant.reload
    assert_kind_of(ActiveSupport::TimeWithZone, @tenant.deleted_at)
  end

  # soft_delete!

  def test_soft_delete_bang_sets_deleted_at
    assert_nil(@tenant.deleted_at)
    @tenant.soft_delete!
    @tenant.reload
    assert_kind_of(ActiveSupport::TimeWithZone, @tenant.deleted_at)
  end
end
