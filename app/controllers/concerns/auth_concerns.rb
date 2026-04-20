module AuthConcerns
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include RenderErrorsConcerns

  def acesso_token
    request.headers['token']
  end

  def logged_in?
    authenticate_with_http_token do |access_token, _options|
      Rails.logger.info "Token: #{access_token}"
      return nil unless access_token

      dados_token = TokenService.decode_token(access_token).first
      return if @usuario = User.find_by(id: dados_token['user_id'])
    rescue StandardError
      standard_error error: { title: 'Problema com a autenticação', message: 'Token inválido ou expirado' },
                     status: :unauthorized
    end
  end

  def current_user
    @current_user ||= @usuario
  end
end