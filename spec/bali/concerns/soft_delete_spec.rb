# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Concerns::SoftDelete do
  let!(:tenant) { Tenant.create(name: 'Test') }
  let!(:soft_deleted_tenant) { Tenant.create(name: 'Test', deleted_at: Time.zone.now) }

  describe '.active_and_deleted' do
    it { expect(Tenant.active_and_deleted).to include tenant }
    it { expect(Tenant.active_and_deleted).to include soft_deleted_tenant }
  end

  describe '.active' do
    it { expect(Tenant.active).to include tenant }
    it { expect(Tenant.active).not_to include soft_deleted_tenant }
  end

  describe '.soft_deleted' do
    it { expect(Tenant.soft_deleted).not_to include tenant }
    it { expect(Tenant.soft_deleted).to include soft_deleted_tenant }
  end

  describe '#active?' do
    it { expect(tenant.active?).to be_truthy }
    it { expect(soft_deleted_tenant.active?).to be_falsey }
  end

  describe '#soft_deleted?' do
    it { expect(tenant.soft_deleted?).to be_falsey }
    it { expect(soft_deleted_tenant.soft_deleted?).to be_truthy }
  end

  describe '#soft_delete' do
    it 'changes deleted_at from NilClass to ActiveSupport::TimeWithZone' do
      expect { tenant.soft_delete }.to change {
        tenant.reload.deleted_at
      }.from(NilClass).to(ActiveSupport::TimeWithZone)
    end
  end

  describe '#soft_delete!' do
    it 'changes deleted_at from NilClass to ActiveSupport::TimeWithZone' do
      expect { tenant.soft_delete! }.to change {
        tenant.reload.deleted_at
      }.from(NilClass).to(ActiveSupport::TimeWithZone)
    end
  end
end
