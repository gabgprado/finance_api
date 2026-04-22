require 'rails_helper'

RSpec.describe TransactionFilterService, type: :service do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user) }
  let(:expense_category) { create(:category, user: user, category_type: 'expense') }
  let(:income_category) { create(:category, user: user, category_type: 'income') }
  let(:other_user) { create(:user) }
  let(:other_account) { create(:account, user: other_user) }

  describe '#call' do
    describe 'filtering by account' do
      let!(:transaction1) { create(:transaction, user: user, account: account, category: expense_category) }
      let(:account2) { create(:account, user: user) }
      let!(:transaction2) { create(:transaction, user: user, account: account2, category: expense_category) }

      it 'returns only transactions from the specified account' do
        result = TransactionFilterService.new(user, account_id: account.id).call
        expect(result).to include(transaction1)
        expect(result).not_to include(transaction2)
      end
    end

    describe 'filtering by category' do
      let!(:expense_transaction) { create(:transaction, user: user, account: account, category: expense_category) }
      let!(:income_transaction) { create(:transaction, :income, user: user, account: account, category: income_category) }

      it 'returns only transactions from the specified category' do
        result = TransactionFilterService.new(user, category_id: expense_category.id).call
        expect(result).to include(expense_transaction)
        expect(result).not_to include(income_transaction)
      end
    end

    describe 'filtering by transaction type' do
      let!(:income_transaction) { create(:transaction, :income, user: user, account: account, category: income_category) }
      let!(:expense_transaction) { create(:transaction, :expense, user: user, account: account, category: expense_category) }
      let!(:transfer_transaction) { create(:transaction, :transfer, user: user, account: account, category: expense_category) }

      it 'returns only transactions of the specified type' do
        result = TransactionFilterService.new(user, transaction_type: 'income').call
        expect(result).to include(income_transaction)
        expect(result).not_to include(expense_transaction, transfer_transaction)
      end
    end

    describe 'filtering by period' do
      let!(:old_transaction) { create(:transaction, user: user, account: account, category: expense_category, date: 10.days.ago.to_date) }
      let!(:recent_transaction) { create(:transaction, user: user, account: account, category: expense_category, date: Time.current.to_date) }
      let!(:future_transaction) { create(:transaction, user: user, account: account, category: expense_category, date: 10.days.from_now.to_date) }

      it 'returns only transactions within the specified date range' do
        start_date = 5.days.ago.to_date
        end_date = 5.days.from_now.to_date
        result = TransactionFilterService.new(user, start_date: start_date, end_date: end_date).call
        expect(result).to include(recent_transaction)
        expect(result).not_to include(old_transaction, future_transaction)
      end
    end

    describe 'combining multiple filters' do
      let(:account2) { create(:account, user: user) }
      let!(:transaction1) { create(:transaction, user: user, account: account, category: expense_category, date: 5.days.ago.to_date, amount: 100.0) }
      let!(:transaction2) { create(:transaction, user: user, account: account, category: expense_category, date: 10.days.ago.to_date, amount: 50.0) }
      let!(:transaction3) { create(:transaction, :income, user: user, account: account, category: income_category, date: 5.days.ago.to_date, amount: 100.0) }
      let!(:transaction4) { create(:transaction, user: user, account: account2, category: expense_category, date: 5.days.ago.to_date, amount: 75.0) }

      it 'returns transactions matching all specified filters' do
        result = TransactionFilterService.new(user, {
          account_id: account.id,
          category_id: expense_category.id,
          transaction_type: 'expense',
          start_date: 7.days.ago.to_date,
          end_date: 2.days.ago.to_date
        }).call
        expect(result).to include(transaction1)
        expect(result).not_to include(transaction2, transaction3, transaction4)
      end
    end

    describe 'pagination' do
      before do
        10.times do
          create(:transaction, user: user, account: account, category: expense_category)
        end
      end

      it 'returns the first page with default per_page' do
        result = TransactionFilterService.new(user, page: 1).call
        expect(result.size).to eq(10)
      end

      it 'returns the correct page with custom per_page' do
        result = TransactionFilterService.new(user, page: 1, per_page: 5).call
        expect(result.size).to eq(5)
      end

      it 'returns the second page' do
        page1 = TransactionFilterService.new(user, page: 1, per_page: 3).call
        page2 = TransactionFilterService.new(user, page: 2, per_page: 3).call
        expect(page1.to_a).not_to include(*page2.to_a)
      end
    end

    describe 'user isolation' do
      let!(:user_transaction) { create(:transaction, user: user, account: account, category: expense_category) }
      let!(:other_user_transaction) { create(:transaction, user: other_user, account: other_account, category: create(:category, user: other_user, category_type: 'expense')) }

      it 'returns only transactions belonging to the current user' do
        result = TransactionFilterService.new(user, {}).call
        expect(result).to include(user_transaction)
        expect(result).not_to include(other_user_transaction)
      end
    end

    describe 'ordering' do
      let!(:transaction1) { create(:transaction, user: user, account: account, category: expense_category, date: 1.day.ago.to_date, created_at: 1.day.ago) }
      let!(:transaction2) { create(:transaction, user: user, account: account, category: expense_category, date: Time.current.to_date, created_at: Time.current) }

      it 'orders by date desc, then created_at desc' do
        result = TransactionFilterService.new(user, {}).call
        expect(result.first).to eq(transaction2)
        expect(result.last).to eq(transaction1)
      end
    end
  end
end
