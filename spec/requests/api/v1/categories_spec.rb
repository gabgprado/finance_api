require 'swagger_helper'

RSpec.describe 'api/v1/categories', type: :request do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{TokenService.encode(user_id: user.id)}" }

  path '/api/v1/categories' do
    get('list categories') do
      tags 'Categories'
      security [Bearer: []]
      description 'Lista as categorias do usuário autenticado'
      produces 'application/vnd.api+json'
      parameter name: :Authorization, in: :header, type: :string

      response(200, 'ok') do
        run_test!
      end
    end

    post('create category') do
      tags 'Categories'
      security [Bearer: []]
      description 'Cria uma nova categoria para o usuário autenticado'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :Authorization, in: :header, type: :string
      parameter name: :category, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'categories' },
              attributes: {
                type: :object,
                properties: {
                  name: { type: :string, example: 'Alimentação' },
                  category_type: { type: :string, example: 'expense' },
                  color: { type: :string, example: '#FF5733' },
                  icon_name: { type: :string, example: 'fast-food' }
                },
                required: %w[name category_type]
              }
            },
            required: %w[type attributes]
          }
        },
        required: %w[data]
      }

      response(201, 'created') do
        let(:category) do
          {
            data: {
              type: 'categories',
              attributes: {
                name: 'Outros',
                category_type: 'expense',
                color: '#95A5A6'
              }
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:category) do
          {
            data: {
              type: 'categories',
              attributes: {
                name: '',
                category_type: 'invalid'
              }
            }
          }
        end
        run_test!
      end
    end
  end

  path '/api/v1/categories/{id}' do
    parameter name: :id, in: :path, type: :string, description: 'id'
    parameter name: :Authorization, in: :header, type: :string

    get('show category') do
      tags 'Categories'
      security [Bearer: []]
      produces 'application/vnd.api+json'

      response(200, 'ok') do
        let(:id) { create(:category, user: user).id }
        run_test!
      end

      response(403, 'forbidden') do
        let(:id) { create(:category, user: create(:user)).id }
        run_test!
      end
    end

    patch('update category') do
      tags 'Categories'
      security [Bearer: []]
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      parameter name: :category_data, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: 'categories' },
              attributes: {
                type: :object,
                properties: {
                  name: { type: :string, example: 'Novo Nome' }
                }
              }
            }
          }
        }
      }

      response(200, 'ok') do
        let(:id) { create(:category, user: user).id }
        let(:category_data) { { data: { type: 'categories', attributes: { name: 'Atualizado' } } } }
        run_test!
      end
    end

    delete('delete category') do
      tags 'Categories'
      security [Bearer: []]

      response(204, 'no content') do
        let(:id) { create(:category, user: user).id }
        run_test!
      end
    end
  end
end
