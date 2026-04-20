require 'swagger_helper'

RSpec.describe 'api/v1/users', type: :request do
  path '/api/v1/users' do
    post('create user') do
      tags 'Users'
      description 'Cria um novo usuário e retorna um token de acesso'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'users' },
              attributes: {
                type: :object,
                properties: {
                  email: { type: :string, example: 'user@example.com' },
                  password: { type: :string, example: 'password123' },
                  password_confirmation: { type: :string, example: 'password123' }
                },
                required: %w[email password password_confirmation]
              }
            },
            required: %w[type attributes]
          }
        },
        required: %w[data]
      }

      response(201, 'created') do
        let(:user) do
          {
            data: {
              type: 'users',
              attributes: {
                email: 'newuser@example.com',
                password: 'password123',
                password_confirmation: 'password123'
              }
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:user) do
          {
            data: {
              type: 'users',
              attributes: {
                email: '',
                password: '123',
                password_confirmation: '123'
              }
            }
          }
        end
        run_test!
      end

      response(415, 'unsupported media type') do
        let(:user) { {} }
        # Simulate wrong content type by NOT setting the header correctly in the helper or manually
        it 'returns 415 when content-type is wrong' do
          post '/api/v1/users', params: user.to_json, headers: { 'Content-Type' => 'application/json' }
          expect(response).to have_http_status(:unsupported_media_type)
        end
      end
    end
  end
end
