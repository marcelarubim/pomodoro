require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'dotenv'
require './config/environments'
require './models/user'
# require './helper'

class JwtAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options

      env[:scopes] = payload['scopes']
      env[:user] = payload['user']
      @app.call env
    rescue JWT::DecodeError
      [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
    rescue JWT::ExpiredSignature
      [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [403, { 'Content-Type' => 'text/plain' },
       ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [403, { 'Content-Type' => 'text/plain' },
       ['The token does not have a valid "issued at" time.']]
    end
  end
end

class Api < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    Dotenv.load
  end

  use JwtAuth

  get '/protected' do
    process_request request, 'view_session' do |req, username|
      @user.username.to_json
    end
  end

  post '/protected' do
    process_request request, 'add_session' do |req, username|
      @user.username.to_json
    end
  end

  def process_request req, scope
    scopes, user = request.env.values_at :scopes, :user
    username = user['username'].to_sym
    @user = User.find_by(username: username) if username

    if scopes.include?('add_session') && @user
      yield req, @user
    else
      halt 403
    end
  end
end

class Public < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    Dotenv.load
  end

  before do
    begin
      if request.body.read(1)
        request.body.rewind
        @request_payload = JSON.parse request.body.read, symbolize_names: true
      end
    rescue JSON::ParserError => e
      request.body.rewind
    end
  end

  post '/signin' do
    @user = User.new(email: @request_payload[:email],
                     password: @request_payload[:password],
                     username: @request_payload[:username])
    if @user.save
      { message: 'User created', token: token(@user.username) }.to_json
    else
      halt 401
    end
  end

  def token(username)
    JWT.encode payload(username, ['view_session', 'add_session', 'view_stats']), ENV['JWT_SECRET'], 'HS256'
  end

  def payload(username, scopes)
    {
      exp: Time.now.to_i + 60 * 60,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      scopes: scopes, #['view_session', 'add_session', 'view_stats']
      user: { username: username }
    }
  end

  post '/signup' do
  end
end
