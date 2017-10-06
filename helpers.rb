require 'sinatra/base'
require 'jwt'

module Sinatra
  module Helpers
    def authenticate!
      @user = User.find_by(username: params[:username])
      @payload, _header = validate
      raise ApiError::InvalidUsername.new, 'User not authorized' if
        @payload['user_id'] != @user.id
      raise ApiError::InvalidUsername.new, 'Action out of user scope' if
        @user.scopes.include?(@payload['scope'])
    rescue *ApiError::JWT_EXCEPTIONS => e
      halt 403, { error: e.class.to_s, message: e.message }.to_json
    rescue ApiError::InvalidUsername => e
      halt 401, { error: e.class.to_s, message: e.message }.to_json
    end

    def validate
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      options = { algorithm: 'HS256',
                  iss: ENV['JWT_ISSUER'],
                  verify_iss: true,
                  aud: ENV['JWT_AUDIENCE'],
                  verify_aud: true }
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

    def token(user, args = {})
      JWT.encode payload(user, args), ENV['JWT_SECRET'], 'HS256'
    end

    def payload(user, args)
      access_payload(user) if args[:grant_type] == 'access_token'
    end

    def access_payload(user)
      {
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        aud: request.url.gsub(request.fullpath, ''),
        scopes: user.scopes,
        user_id: user.id
      }
    end

    def process_request(req, scope)
      if @user.scopes&.include?(scope) || @user.scopes&.include?('admin')
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

      class AuthenticationError < StandardError; end
      class InvalidUsername < AuthenticationError; end
      class InvalidScope < AuthenticationError; end
    end
  end
end
