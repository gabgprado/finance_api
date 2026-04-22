require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:category) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:transaction_type) }
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:category_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
    it { is_expected.to validate_inclusion_of(:transaction_type).in_array(Transaction::TRANSACTION_TYPES) }

    describe 'category and account ownership' do
      let(:user) { create(:user) }
      let(:other_user) { create(:user) }
      let(:user_account) { create(:account, user: user) }
      let(:other_account) { create(:account, user: other_user) }
      let(:user_category) { create(:category, user: user, category_type: 'expense') }
      let(:other_category) { create(:category, user: other_user, category_type: 'expense') }

      it 'is invalid when account does not belong to user' do
        transaction = build(:transaction, user: user, account: other_account, category: user_category)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:account_id]).to include('must belong to the same user')
      end

      it 'is invalid when category does not belong to user' do
        transaction = build(:transaction, user: user, account: user_account, category: other_category)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:category_id]).to include('must belong to the same user')
      end
    end

    describe 'category type matching transaction type' do
      let(:user) { create(:user) }
      let(:account) { create(:account, user: user) }
      let(:income_category) { create(:category, user: user, category_type: 'income') }
      let(:expense_category) { create(:category, user: user, category_type: 'expense') }

      it 'is invalid when income transaction uses expense category' do
        transaction = build(:transaction, user: user, account: account, transaction_type: 'income', category: expense_category)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:category]).to be_present
      end

      it 'is invalid when expense transaction uses income category' do
        transaction = build(:transaction, user: user, account: account, transaction_type: 'expense', category: income_category)
        expect(transaction).not_to be_valid
        expect(transaction.errors[:category]).to be_present
      end

      it 'is valid when income transaction uses income category' do
        transaction = build(:transaction, user: user, account: account, transaction_type: 'income', category: income_category)
        expect(transaction).to be_valid
      end

      it 'is valid when expense transaction uses expense category' do
        transaction = build(:transaction, user: user, account: account, transaction_type: 'expense', category: expense_category)
        expect(transaction).to be_valid
      end

      it 'is valid when transfer transaction uses expense category' do
        transaction = build(:transaction, user: user, account: account, transaction_type: 'transfer', category: expense_category)
        expect(transaction).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:account) { create(:account, user: user) }
    let(:income_category) { create(:category, user: user, category_type: 'income') }
    let(:expense_category) { create(:category, user: user, category_type: 'expense') }

    describe '.by_period' do
      let!(:transaction1) { create(:transaction, user: user, account: account, category: expense_category, date: 5.days.ago.to_date) }
      let!(:transaction2) { create(:transaction, user: user, account: account, category: expense_category, date: Time.current.to_date) }
      let!(:transaction3) { create(:transaction, user: user, account: account, category: expense_category, date: 5.days.from_now.to_date) }

      it 'returns transactions within the date range' do
        start_date = 3.days.ago.to_date
        end_date = 3.days.from_now.to_date
        result = Transaction.by_period(start_date, end_date)
        expect(result).to include(transaction2)
        expect(result).not_to include(transaction1, transaction3)
      end
    end

    describe '.by_category' do
      let!(:expense_transaction) { create(:transaction, user: user, account: account, category: expense_category) }
      let!(:income_transaction) { create(:transaction, :income, user: user, account: account, category: income_category) }

      it 'returns transactions with the specified category' do
        result = Transaction.by_category(expense_category.id)
        expect(result).to include(expense_transaction)
        expect(result).not_to include(income_transaction)
      end
    end

    describe '.by_account' do
      let(:account2) { create(:account, user: user) }
      let!(:transaction1) { create(:transaction, user: user, account: account, category: expense_category) }
      let!(:transaction2) { create(:transaction, user: user, account: account2, category: expense_category) }

      it 'returns transactions for the specified account' do
        result = Transaction.by_account(account.id)
        expect(result).to include(transaction1)
        expect(result).not_to include(transaction2)
      end
    end

    describe '.by_type' do
      let!(:income_transaction) { create(:transaction, :income, user: user, account: account, category: income_category) }
      let!(:expense_transaction) { create(:transaction, :expense, user: user, account: account, category: expense_category) }
      let!(:transfer_transaction) { create(:transaction, :transfer, user: user, account: account, category: expense_category) }

      it 'returns transactions of the specified type' do
        result = Transaction.by_type('income')
        expect(result).to include(income_transaction)
        expect(result).not_to include(expense_transaction, transfer_transaction)
      end
    end

    describe '.ordered' do
      let!(:transaction1) { create(:transaction, user: user, account: account, category: expense_category, date: 1.day.ago.to_date, created_at: 1.day.ago) }
      let!(:transaction2) { create(:transaction, user: user, account: account, category: expense_category, date: Time.current.to_date, created_at: Time.current) }

      it 'orders by date desc, then created_at desc' do
        result = Transaction.ordered.to_a
        expect(result.first).to eq(transaction2)
        expect(result.last).to eq(transaction1)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create :update_account_balance' do
      let(:user) { create(:user) }
      let(:account) { create(:account, user: user, balance: 1000.0) }
      let(:expense_category) { create(:category, user: user, category_type: 'expense') }
      let(:income_category) { create(:category, user: user, category_type: 'income') }

      context 'when creating an income transaction' do
        it 'increases account balance' do
          initial_balance = account.balance
          create(:transaction, :income, user: user, account: account, category: income_category, amount: 100.0)
          expect(account.reload.balance).to eq(initial_balance + 100.0)
        end
      end

      context 'when creating an expense transaction' do
        it 'decreases account balance' do
          initial_balance = account.balance
          create(:transaction, :expense, user: user, account: account, category: expense_category, amount: 100.0)
          expect(account.reload.balance).to eq(initial_balance - 100.0)
        end
      end

      context 'when creating a transfer transaction' do
        it 'decreases account balance' do
          initial_balance = account.balance
          create(:transaction, :transfer, user: user, account: account, category: expense_category, amount: 100.0)
          expect(account.reload.balance).to eq(initial_balance - 100.0)
        end
      end
    end

    describe 'after_destroy :revert_account_balance' do
      let(:user) { create(:user) }
      let(:account) { create(:account, user: user, balance: 1000.0) }
      let(:expense_category) { create(:category, user: user, category_type: 'expense') }
      let(:income_category) { create(:category, user: user, category_type: 'income') }

      context 'when destroying an income transaction' do
        it 'decreases account balance' do
          transaction = create(:transaction, :income, user: user, account: account, category: income_category, amount: 100.0)
          balance_after_create = account.reload.balance
          transaction.destroy
          expect(account.reload.balance).to eq(balance_after_create - 100.0)
        end
      end

      context 'when destroying an expense transaction' do
        it 'increases account balance' do
          transaction = create(:transaction, :expense, user: user, account: account, category: expense_category, amount: 100.0)
          balance_after_create = account.reload.balance
          transaction.destroy
          expect(account.reload.balance).to eq(balance_after_create + 100.0)
        end
      end
    end

    describe 'before_update :revert_and_reapply_balance' do
      let(:user) { create(:user) }
      let(:account) { create(:account, user: user, balance: 1000.0) }
      let(:expense_category) { create(:category, user: user, category_type: 'expense') }
      let(:income_category) { create(:category, user: user, category_type: 'income') }

      context 'when updating transaction amount' do
        it 'reverts old balance impact and applies new one' do
          transaction = create(:transaction, :expense, user: user, account: account, category: expense_category, amount: 100.0)
          balance_after_create = account.reload.balance
          
          transaction.update(amount: 50.0)
          expect(account.reload.balance).to eq(balance_after_create + 100.0 - 50.0)
        end
      end

      context 'when updating transaction type from expense to income' do
        it 'reverts old balance impact and applies new one' do
          transaction = create(:transaction, :expense, user: user, account: account, category: expense_category, amount: 100.0)
          balance_after_create = account.reload.balance
          
          transaction.update(transaction_type: 'income', category: income_category)
          # Old impact: -100, New impact: +100, so total change is +200
          expect(account.reload.balance).to eq(balance_after_create + 100.0 + 100.0)
        end
      end

      context 'when updating transaction without amount or type change' do
        it 'does not affect account balance' do
          transaction = create(:transaction, :expense, user: user, account: account, category: expense_category, amount: 100.0)
          balance_after_create = account.reload.balance
          
          transaction.update(description: 'Updated description')
          expect(account.reload.balance).to eq(balance_after_create)
        end
      end
    end
  end
end
