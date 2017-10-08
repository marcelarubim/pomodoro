require 'sinatra/base'
require 'jwt'

module Sinatra
  module Helpers
    def authenticate!
      @payload, _header = decode_token!
      validate_token!
    rescue *ApiError::JWT_EXCEPTIONS => e
      halt 403, { error: e.class.to_s, message: e.message }.to_json
    end

    def decode_token!
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      Token.decode(bearer)
    end

    def validate_token!
      token_errors!
      authorization_errors!
    rescue ActiveRecord::RecordNotFound => e
      halt 404, { error: e.class.to_s, message: e.message }.to_json
    rescue *ApiError::JWT_EXCEPTIONS => e
      halt 403, { error: e.class.to_s, message: e.message }.to_json
    end

    def token_errors!
      raise JWT::VerificationError, 'Invalid token' if
        Token.find(@payload['token_id']).blacklist
    end

    def authorization_errors!
      current_user!
      return if request.path == '/user/me' ||
                request.path.start_with?('/user/me/')
      raise JWT::VerificationError, 'User not authorized' if
        @payload['user_id'] != @user&.id
      raise JWT::VerificationError, 'Invalid scope' if
        @user.scopes.include?(@payload['scope'])
    end

    def current_user!
      @user = if params.key?(:username)
                User.find_by(username: params[:username])
              elsif !@request_body.nil? && @request_body.key?('id')
                User.find(@request_body['id'])
              else
                User.find(@payload['user_id'])
              end
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

    def process_request(req, scope)
      if @user.scopes&.include?(scope) || @user.scopes&.include?('admin')
        yield req
      else
        halt 403, { error: "Action out of user's scope" }.to_json
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
