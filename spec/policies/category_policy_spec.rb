require 'rails_helper'

RSpec.describe CategoryPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:category) { create(:category, user: user) }

  subject { described_class.new(user, category) }

  describe 'permissions' do
    it 'permits index' do
      expect(described_class.new(user, Category).index?).to be true
    end

    it 'permits owner to show' do
      expect(subject.show?).to be true
    end

    it 'denies non-owner to show' do
      expect(described_class.new(other_user, category).show?).to be false
    end

    it 'permits create' do
      expect(subject.create?).to be true
    end

    it 'permits owner to update' do
      expect(subject.update?).to be true
    end

    it 'denies non-owner to update' do
      expect(described_class.new(other_user, category).update?).to be false
    end

    it 'permits owner to destroy' do
      expect(subject.destroy?).to be true
    end

    it 'denies non-owner to destroy' do
      expect(described_class.new(other_user, category).destroy?).to be false
    end
  end

  describe 'scope' do
    it 'returns categories belonging to user' do
      create(:category, user: other_user)
      scope = CategoryPolicy::Scope.new(user, Category).resolve
      expect(scope).to include(category)
      expect(scope.count).to eq(7) # 1 created here + 6 default categories
    end
  end
end
