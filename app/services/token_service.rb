module TokenService
  class << self
    JWT_SECRET ||= Rails.application.config.jwt_secret
    ALGORITHM ||= 'HS256'.freeze

    def encode(payload)
      payload[:exp] = 1.hour.from_now.to_i
      JWT.encode(payload, JWT_SECRET, ALGORITHM)
    end

    def decode_token(token)
      JWT.decode(token, JWT_SECRET, true, algorithm: ALGORITHM)
    rescue JWT::DecodeError => e
      e
    end
  end
end