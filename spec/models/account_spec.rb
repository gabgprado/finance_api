require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_inclusion_of(:account_type).in_array(Account::ACCOUNT_TYPES) }

    context 'when account_type is not credit' do
      subject { build(:account, account_type: 'checking') }
      it { is_expected.to validate_numericality_of(:balance).is_greater_than_or_equal_to(0) }
    end

    context 'when account_type is credit' do
      subject { build(:account, account_type: 'credit') }
      it { is_expected.to validate_numericality_of(:balance) }
      it 'allows negative balance' do
        subject.balance = -100.0
        expect(subject).to be_valid
      end
    end
  end

  describe 'scopes' do
    it 'orders by created_at desc' do
      account1 = create(:account, created_at: 1.day.ago)
      account2 = create(:account, created_at: Time.current)
      expect(Account.all).to eq([account2, account1])
    end
  end
end
