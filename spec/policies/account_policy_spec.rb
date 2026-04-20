require 'rails_helper'

RSpec.describe AccountPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:account) { create(:account, user: user) }

  subject { described_class.new(user, account) }

  describe 'permissions' do
    it 'permits index' do
      expect(described_class.new(user, Account).index?).to be true
    end

    it 'permits owner to show' do
      expect(subject.show?).to be true
    end

    it 'denies non-owner to show' do
      expect(described_class.new(other_user, account).show?).to be false
    end

    it 'permits create' do
      expect(subject.create?).to be true
    end

    it 'permits owner to update' do
      expect(subject.update?).to be true
    end

    it 'denies non-owner to update' do
      expect(described_class.new(other_user, account).update?).to be false
    end

    it 'permits owner to destroy' do
      expect(subject.destroy?).to be true
    end

    it 'denies non-owner to destroy' do
      expect(described_class.new(other_user, account).destroy?).to be false
    end
  end

  describe 'scope' do
    it 'returns accounts belonging to user' do
      create(:account, user: other_user)
      scope = AccountPolicy::Scope.new(user, Account).resolve
      expect(scope).to include(account)
      expect(scope.count).to eq(1)
    end
  end
end
