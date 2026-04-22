require 'swagger_helper'

RSpec.describe 'api/v1/transactions', type: :request do
  let(:user) { create(:user) }
  let(:account) { create(:account, user: user, balance: 5000.0) }
  let(:expense_category) { create(:category, user: user, category_type: 'expense') }
  let(:income_category) { create(:category, user: user, category_type: 'income') }
  let(:Authorization) { "Bearer #{TokenService.encode(user_id: user.id)}" }

  path '/api/v1/transactions' do
    get('list transactions') do
      tags 'Transactions'
      security [Bearer: []]
      description 'Lista as transações do usuário autenticado com filtros opcionais'
      produces 'application/vnd.api+json'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :account_id, in: :query, type: :string, required: false
      parameter name: :category_id, in: :query, type: :string, required: false
      parameter name: :transaction_type, in: :query, type: :string, required: false
      parameter name: :start_date, in: :query, type: :string, format: :date, required: false
      parameter name: :end_date, in: :query, type: :string, format: :date, required: false
      parameter name: :page, in: :query, type: :integer, required: false
      parameter name: :per_page, in: :query, type: :integer, required: false

      response(200, 'ok') do
        let!(:transaction) { create(:transaction, user: user, account: account, category: expense_category) }
        run_test!
      end

      response(200, 'filtered by account') do
        let(:account_id) { account.id }
        let!(:transaction) { create(:transaction, user: user, account: account, category: expense_category) }
        let(:other_account) { create(:account, user: user) }
        let!(:other_transaction) { create(:transaction, user: user, account: other_account, category: expense_category) }
        run_test! do |response|
          expect(JSON.parse(response.body)['data'].length).to eq(1)
        end
      end

      response(200, 'filtered by category') do
        let(:category_id) { expense_category.id }
        let!(:expense_tx) { create(:transaction, user: user, account: account, category: expense_category) }
        let!(:income_tx) { create(:transaction, :income, user: user, account: account, category: income_category) }
        run_test! do |response|
          expect(JSON.parse(response.body)['data'].length).to eq(1)
        end
      end

      response(200, 'filtered by transaction type') do
        let(:transaction_type) { 'income' }
        let!(:income_tx) { create(:transaction, :income, user: user, account: account, category: income_category) }
        let!(:expense_tx) { create(:transaction, :expense, user: user, account: account, category: expense_category) }
        run_test! do |response|
          expect(JSON.parse(response.body)['data'].length).to eq(1)
        end
      end

      response(200, 'filtered by period') do
        let(:start_date) { 5.days.ago.to_date.to_s }
        let(:end_date) { 5.days.from_now.to_date.to_s }
        let!(:recent_tx) { create(:transaction, user: user, account: account, category: expense_category, date: Time.current.to_date) }
        let!(:old_tx) { create(:transaction, user: user, account: account, category: expense_category, date: 10.days.ago.to_date) }
        run_test! do |response|
          expect(JSON.parse(response.body)['data'].length).to eq(1)
        end
      end

      response(200, 'with pagination') do
        let(:page) { 1 }
        let(:per_page) { 5 }
        before do
          10.times do
            create(:transaction, user: user, account: account, category: expense_category)
          end
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data'].length).to eq(5)
          expect(data['meta']['current_page']).to eq(1)
          expect(data['meta']['total_count']).to eq(10)
        end
      end
    end

    post('create transaction') do
      tags 'Transactions'
      security [Bearer: []]
      description 'Cria uma nova transação para o usuário autenticado'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :transaction, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'transactions' },
              attributes: {
                type: :object,
                properties: {
                  amount: { type: :number, example: 100.0 },
                  description: { type: :string, example: 'Lunch' },
                  transaction_type: { type: :string, example: 'expense' },
                  date: { type: :string, format: :date, example: '2025-04-21' },
                  account_id: { type: :string, format: :uuid },
                  category_id: { type: :string, format: :uuid }
                },
                required: %w[amount transaction_type date account_id category_id]
              }
            },
            required: %w[type attributes]
          }
        },
        required: %w[data]
      }

      response(201, 'created') do
        let(:transaction) do
          {
            data: {
              type: 'transactions',
              attributes: {
                amount: 100.0,
                description: 'Lunch expense',
                transaction_type: 'expense',
                date: Time.current.to_date.to_s,
                account_id: account.id,
                category_id: expense_category.id
              }
            }
          }
        end
        run_test! do |response|
          expect(account.reload.balance).to eq(4900.0)
          body = JSON.parse(response.body)
          expect(body['data']['attributes']['amount']).to eq(100.0)
        end
      end

      response(422, 'unprocessable entity - invalid amount') do
        let(:transaction) do
          {
            data: {
              type: 'transactions',
              attributes: {
                amount: -50.0,
                transaction_type: 'expense',
                date: Time.current.to_date.to_s,
                account_id: account.id,
                category_id: expense_category.id
              }
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable entity - mismatched category type') do
        let(:transaction) do
          {
            data: {
              type: 'transactions',
              attributes: {
                amount: 100.0,
                transaction_type: 'expense',
                date: Time.current.to_date.to_s,
                account_id: account.id,
                category_id: income_category.id
              }
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/transactions/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'id'
    parameter name: :Authorization, in: :header, type: :string

    get('show transaction') do
      tags 'Transactions'
      security [Bearer: []]
      produces 'application/vnd.api+json'

      response(200, 'ok') do
        let(:id) { create(:transaction, user: user, account: account, category: expense_category).id }
        run_test!
      end

      response(403, 'forbidden - not owner') do
        let(:other_user) { create(:user) }
        let(:other_account) { create(:account, user: other_user) }
        let(:other_category) { create(:category, user: other_user, category_type: 'expense') }
        let(:id) { create(:transaction, user: other_user, account: other_account, category: other_category).id }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { SecureRandom.uuid }
        run_test!
      end
    end

    patch('update transaction') do
      tags 'Transactions'
      security [Bearer: []]
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :transaction_data, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string },
              attributes: {
                type: :object,
                properties: {
                  amount: { type: :number },
                  description: { type: :string }
                }
              }
            }
          }
        }
      }

      response(200, 'ok') do
        let(:transaction) { create(:transaction, user: user, account: account, category: expense_category, amount: 100.0) }
        let(:id) { transaction.id }
        let(:transaction_data) { { data: { type: 'transactions', attributes: { amount: 50.0 } } } }
        run_test! do |response|
          expect(account.reload.balance).to eq(4950.0)
        end
      end

      response(200, 'ok - change transaction type') do
        let(:transaction) { create(:transaction, user: user, account: account, category: expense_category, amount: 100.0) }
        let(:id) { transaction.id }
        let(:transaction_data) do
          {
            data: {
              type: 'transactions',
              attributes: { transaction_type: 'income', category_id: income_category.id }
            }
          }
        end
        run_test! do |response|
          expect(account.reload.balance).to eq(5100.0)
        end
      end
    end

    delete('delete transaction') do
      tags 'Transactions'
      security [Bearer: []]

      response(204, 'no content') do
        let(:transaction) { create(:transaction, user: user, account: account, category: expense_category, amount: 100.0) }
        let(:id) { transaction.id }
        run_test! do |response|
          expect(account.reload.balance).to eq(5100.0)
        end
      end
    end
  end
end
