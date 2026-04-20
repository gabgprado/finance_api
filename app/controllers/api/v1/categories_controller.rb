module Api
  module V1
    class CategoriesController < ApplicationController
      before_action :set_category, only: %i[show update destroy]

      def index
        @categories = query_prepare(policy_scope(Category))
        standard_index(@categories)
      end

      def show
        authorize @category
        standard_show(@category)
      end

      def create
        @category = current_user.categories.build(category_params)
        authorize @category
        if @category.save
          standard_create(@category)
        else
          render_json_api_msg_errors('Erro ao criar categoria', @category.errors.full_messages.join(', '), 422)
        end
      end

      def update
        authorize @category
        if @category.update(category_params)
          render_api(@category)
        else
          render_json_api_msg_errors('Erro ao atualizar categoria', @category.errors.full_messages.join(', '), 422)
        end
      end

      def destroy
        authorize @category
        @category.destroy
        head :no_content
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        create_params(%i[name color icon_name category_type])
      end
    end
  end
end
