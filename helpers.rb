require 'sinatra/base'

module Sinatra
  module Helpers
    def authenticate!
      payload, _header = validate
      %i[scopes user_id].each { |k| env[k] = payload[k.to_s] }
      raise ArgumentError.new('Invalid payload with nil value.') if payload.nil?
    rescue *ApiError::JWT_EXCEPTIONS => e
      halt 403, { error: e.class.to_s, message: e.message }.to_json
    end

    def validate
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      options = { algorithm: 'HS256',
                  iss: ENV['JWT_ISSUER'],
                  aud: ENV['JWT_AUDIENCE'] }
      JWT.decode bearer, ENV['JWT_SECRET'], true, options
    end

    def json_body
      if request.body.read(1)
        request.body.rewind
        @request_body = JSON.parse request.body.read, symbolize_names: true
      end
    rescue JSON::ParserError => e
      request.body.rewind
      halt 401, { error: e.class.to_s, message: e.message }.to_json
    end

    def token(user_id, scopes, type = 0)
      case type
      when 0 # access_token
        JWT.encode access_payload(user_id, scopes), ENV['JWT_SECRET'], 'HS256'
      when 1 # access_token
        JWT.encode id_payload(user_id, scopes), ENV['JWT_SECRET'], 'HS256'
      when 2 # refresh_token
        JWT.encode refresh_payload(user_id, scopes), ENV['JWT_SECRET'], 'HS256'
      end
    end

    def access_payload(user_id, scopes)
      {
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        aud: request.url.gsub(request.fullpath, ''),
        scopes: scopes, # ['view_session', 'add_session', 'view_stats']
        user_id: user_id
      }
    end

    def refresh_payload(user_id, scopes)
      {
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        aud: request.url.gsub(request.fullpath, ''),
        scopes: scopes, # ['view_session', 'add_session', 'view_stats']
        user_id: user_id
      }
    end

    def id_payload(user_id, scopes)
      {
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        aud: request.url.gsub(request.fullpath, ''),
        scopes: scopes, # ['view_session', 'add_session', 'view_stats']
        user_id: user_id
      }
    end

    def process_request(req, scope, username)
      scopes, user_id = request.env.values_at :scopes, :user_id
      @user = User.find_by(username: username)
      if (scopes&.include?(scope) || scopes&.include?('admin')) &&
         @user&.id == user_id
        yield req
      else
        halt 403
      end
    end

    module ApiError
      JWT_EXCEPTIONS = [
        JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature,
        JWT::IncorrectAlgorithm, JWT::InvalidAudError, JWT::InvalidIatError,
        JWT::InvalidIssuerError, JWT::InvalidJtiError, JWT::InvalidSubError,
        JWT::VerificationError
      ].freeze
    end
  end
end
