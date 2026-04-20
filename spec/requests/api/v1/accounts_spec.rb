require 'swagger_helper'

RSpec.describe 'api/v1/accounts', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{TokenService.encode(user_id: user.id)}" }

  path '/api/v1/accounts' do
    get('list accounts') do
      tags 'Accounts'
      security [Bearer: []]
      description 'Lista as contas do usuário autenticado'
      produces 'application/vnd.api+json'
      parameter name: :Authorization, in: :header, type: :string

      response(200, 'ok') do
        let!(:account) { create(:account, user: user) }
        run_test!
      end
    end

    post('create account') do
      tags 'Accounts'
      security [Bearer: []]
      description 'Cria uma nova conta para o usuário autenticado'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :account, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'accounts' },
              attributes: {
                type: :object,
                properties: {
                  name: { type: :string, example: 'Conta Corrente' },
                  account_type: { type: :string, example: 'checking' },
                  balance: { type: :number, example: 1000.0 },
                  currency: { type: :string, example: 'BRL' }
                },
                required: %w[name account_type]
              }
            },
            required: %w[type attributes]
          }
        },
        required: %w[data]
      }

      response(201, 'created') do
        let(:account) do
          {
            data: {
              type: 'accounts',
              attributes: {
                name: 'Poupança',
                account_type: 'savings',
                balance: 500.0,
                currency: 'BRL'
              }
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:account) do
          {
            data: {
              type: 'accounts',
              attributes: {
                name: '',
                account_type: 'invalid'
              }
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/accounts/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'id'
    parameter name: :Authorization, in: :header, type: :string

    get('show account') do
      tags 'Accounts'
      security [Bearer: []]
      produces 'application/vnd.api+json'

      response(200, 'ok') do
        let(:id) { create(:account, user: user).id }
        run_test!
      end

      response(403, 'forbidden') do
        let(:id) { create(:account, user: create(:user)).id }
        run_test!
      end

      response(404, 'not found') do
        let(:id) { '0' }
        run_test!
      end
    end

    patch('update account') do
      tags 'Accounts'
      security [Bearer: []]
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :account_data, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'accounts' },
              attributes: {
                type: :object,
                properties: {
                  name: { type: :string, example: 'Nome Atualizado' }
                }
              }
            }
          }
        }
      }

      response(200, 'ok') do
        let(:id) { create(:account, user: user).id }
        let(:account_data) { { data: { type: 'accounts', attributes: { name: 'Novo Nome' } } } }
        run_test!
      end
    end

    delete('delete account') do
      tags 'Accounts'
      security [Bearer: []]

      response(204, 'no content') do
        let(:id) { create(:account, user: user).id }
        run_test!
      end
    end
  end
end
