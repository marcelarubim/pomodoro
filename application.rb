require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'dotenv'
require './config/environments'
require './models/user'
require './models/session'
# require './helper'

class JwtAuth
  def initialize(app)
    @app = app
  end

  def response(code, msg)
    request&.accept&.each do |type|
      case type.to_s
      when 'text/html'
        halt [code, msg]
      when 'text/json'
        { message: msg, status: code }.to_json
      when 'text/plain'
        halt [code, { 'Content-Type' => 'text/plain' }, [msg]]
      end
    end
    # error 406
  end

  def call(env)
    options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
    bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
    payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options
    env[:scopes] = payload['scopes']
    env[:user] = payload['user']
    @app.call env
  rescue JWT::ExpiredSignature
    [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
  rescue JWT::InvalidIssuerError
    [403, { 'Content-Type' => 'text/plain' },
     ['The token does not have a valid issuer.']]
  rescue JWT::InvalidIatError
    [403, { 'Content-Type' => 'text/plain' },
     ['The token does not have a valid "issued at" time.']]
  rescue JWT::DecodeError
    [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
  end
end

class Api < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    Dotenv.load
  end

  use JwtAuth
  before do
    begin
      if request.body.read(1)
        request.body.rewind
        @request_body = JSON.parse request.body.read, symbolize_names: true
      end
    rescue JSON::ParserError => e
      request.body.rewind
    end
  end

  get '/user/:username' do
    process_request request, 'view_session', params['username'] do |req|
      { user: @user.username, message: 'get' }.to_json
    end
  end

  post '/user/:username/sessions/new' do
    process_request request, 'add_session', params['username'] do |req|
      new_session = Session.new(title: @request_body[:title],
                                start: @request_body[:start],
                                final: @request_body[:final])
      @user.sessions << new_session
      if @user.save
        { user: @user.username, message: 'post' }.to_json
      else
        halt 401, new_session.errors.full_messages
      end
    end
  end

  def process_request(req, scope, username)
    scopes, user = request.env.values_at :scopes, :user
    @user = User.find_by(username: username) if user['username'] == username
    if (scopes.include?(scope) || scopes.include?('admin')) && @user
      yield req
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

  get '/' do
    { message: 'Tomato Api' }.to_json
  end

  post '/register' do
    @user = User.new(email: @request_payload[:email],
                     username: @request_payload[:username],
                     password: @request_payload[:password])
                     # role: @request_payload[:role])
    if @user.save
      { message: 'User created',
        token: token(@user.username, @user.role_authorization) }.to_json
    else
      halt 401
    end
  end

  post '/signin' do
    @user = User.find_by(username: @request_payload[:username])
    if @user.password == @request_payload[:password]
      halt 200, { token: token(@user.username, @user.role_authorization),
                  message: 'User signed in' }.to_json
    else
      halt 401, { message: 'Username/password don\'t match' }.to_json
    end
  end

  def token(username, scopes)
    JWT.encode payload(username, scopes), ENV['JWT_SECRET'], 'HS256'
  end

  def payload(username, scopes)
    {
      exp: Time.now.to_i + 60 * 60,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      scopes: scopes, # ['view_session', 'add_session', 'view_stats']
      user: { username: username }
    }
  end
end
