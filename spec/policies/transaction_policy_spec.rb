require 'rails_helper'

RSpec.describe TransactionPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:category) { create(:category, user: user, category_type: 'expense') }
  let(:transaction) { create(:transaction, user: user, account: account, category: category) }

  subject { described_class.new(user, transaction) }

  describe 'permissions' do
    it 'permits index' do
      expect(described_class.new(user, Transaction).index?).to be true
    end

    it 'permits owner to show' do
      expect(subject.show?).to be true
    end

    it 'denies non-owner to show' do
      other_account = create(:account, user: other_user)
      other_category = create(:category, user: other_user, category_type: 'expense')
      other_transaction = create(:transaction, user: other_user, account: other_account, category: other_category)
      expect(described_class.new(user, other_transaction).show?).to be false
    end

    it 'permits create' do
      expect(subject.create?).to be true
    end

    it 'permits owner to update' do
      expect(subject.update?).to be true
    end

    it 'denies non-owner to update' do
      other_account = create(:account, user: other_user)
      other_category = create(:category, user: other_user, category_type: 'expense')
      other_transaction = create(:transaction, user: other_user, account: other_account, category: other_category)
      expect(described_class.new(user, other_transaction).update?).to be false
    end

    it 'permits owner to destroy' do
      expect(subject.destroy?).to be true
    end

    it 'denies non-owner to destroy' do
      other_account = create(:account, user: other_user)
      other_category = create(:category, user: other_user, category_type: 'expense')
      other_transaction = create(:transaction, user: other_user, account: other_account, category: other_category)
      expect(described_class.new(user, other_transaction).destroy?).to be false
    end
  end

  describe 'scope' do
    it 'returns transactions belonging to user' do
      other_account = create(:account, user: other_user)
      other_category = create(:category, user: other_user, category_type: 'expense')
      create(:transaction, user: other_user, account: other_account, category: other_category)
      
      scope = TransactionPolicy::Scope.new(user, Transaction).resolve
      expect(scope).to include(transaction)
      expect(scope.count).to eq(1)
    end
  end
end
