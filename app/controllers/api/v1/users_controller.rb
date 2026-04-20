module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :authorized?, only: [:create]
      skip_before_action :logged_in?, only: [:create]

      def create
        user = User.new(user_params)
        user.ativo = true
        if user.save
          token = TokenService.encode(user_id: user.id)
          render json: { token: token, user: UserSerializer.new(user) }, status: :created
        else
          render_json_api_msg_errors('Erro ao cadastrar', user.errors.full_messages.join(', '), 422)
        end
      end

      private

      def user_params
        create_params(%i[email password password_confirmation])
      end
    end
  end
end
