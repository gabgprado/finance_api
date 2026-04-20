require 'swagger_helper'

RSpec.describe 'api/v1/sessions', type: :request do
  path '/api/v1/login' do
    post('create session') do
      tags 'Sessions'
      description 'Autentica um usuário e retorna um token JWT'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      
      parameter name: :login, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'sessions' },
              attributes: {
                type: :object,
                properties: {
                  email: { type: :string, example: 'user@example.com' },
                  password: { type: :string, example: 'password123' }
                },
                required: %w[email password]
              }
            },
            required: %w[type attributes]
          }
        },
        required: %w[data]
      }

      response(200, 'ok') do
        let!(:existing_user) { create(:user, email: 'auth@example.com', password: 'password123') }
        let(:login) do
          {
            data: {
              type: 'sessions',
              attributes: {
                email: 'auth@example.com',
                password: 'password123'
              }
            }
          }
        end
        run_test!
      end

      response(401, 'unauthorized') do
        let(:login) do
          {
            data: {
              type: 'sessions',
              attributes: {
                email: 'wrong@example.com',
                password: 'wrong'
              }
            }
          }
        end
        run_test!
      end
    end
  end
end
