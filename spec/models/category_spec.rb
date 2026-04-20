require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:category) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:user_id) }
    it { is_expected.to validate_inclusion_of(:category_type).in_array(Category::CATEGORY_TYPES) }
    it { is_expected.to allow_value('#FF0000').for(:color) }
    it { is_expected.not_to allow_value('invalid').for(:color) }
  end

  describe 'scopes' do
    it 'orders by created_at desc' do
      category1 = create(:category, created_at: 1.day.ago)
      category2 = create(:category, created_at: Time.current)
      expect(Category.where(id: [category1.id, category2.id])).to eq([category2, category1])
    end
  end
end
