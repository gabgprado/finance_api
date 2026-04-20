module AuthHelpers
  def auth_headers(user)
    token = TokenService.encode(user_id: user.id)
    {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/vnd.api+json'
    }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
