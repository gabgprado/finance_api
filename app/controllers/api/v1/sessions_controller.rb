module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authorized?, only: [:create]
      skip_before_action :logged_in?, only: [:create]

      def create
        login_data = create_params(%i[email password])
        user = User.find_by(email: login_data[:email])
        if user&.authenticate(login_data[:password])
          if user.ativo
            token = TokenService.encode(user_id: user.id)
            render json: { token:, user: UserSerializer.new(user) }, status: :ok
          else
            render_json_api_msg_errors('Usuário inativo', 'Ative seu usuário para acessar.', 401)
          end
        else
          render_json_api_msg_errors('Credenciais inválidas', 'Email ou senha incorretos.', 401)
        end
      end
    end
  end
end
