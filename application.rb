require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'dotenv'
require './config/environments'
require './models/user'
require './models/session'

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
    options = {
      algorithm: 'HS256',
      iss: ENV['JWT_ISSUER'],
      aud: ENV['JWT_AUDIENCE']
    }
    bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
    payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options
    env[:scopes] = payload['scopes']
    env[:user_id] = payload['user_id']
    @app.call env
  rescue JWT::ExpiredSignature => e
    [403, { 'Content-Type' => 'application/json' },
     [{ error: e.class.to_s, message: e.message }.to_json]]
  rescue JWT::InvalidIssuerError => e
    [403, { 'Content-Type' => 'application/json' },
     [{ error: e.class.to_s, message: e.message }.to_json]]
  rescue JWT::InvalidIatError => e
    [403, { 'Content-Type' => 'application/json' },
     [{ error: e.class.to_s, message: e.message }.to_json]]
  rescue JWT::InvalidAudError => e
    [403, { 'Content-Type' => 'application/json' },
     [{ error: e.class.to_s, message: e.message }.to_json]]
  rescue JWT::DecodeError => e
    [401, { 'Content-Type' => 'application/json' },
     [{ error: e.class.to_s, message: e.message }.to_json]]
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
    scopes, user_id = request.env.values_at :scopes, :user_id
    @user = User.find_by(username: username)
    if (scopes.include?(scope) || scopes.include?('admin')) &&
       @user&.id == user_id
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
      halt 401, { error: @user.errors.full_messages }.to_json
    end
  end

  post '/signin' do
    @user = if @request_payload[:login]&.include? '@'
              User.find_by(email: @request_payload[:login])
            else
              User.find_by(username: @request_payload[:login])
            end
    if @user.hash == @request_payload[:password]
      halt 200, { token: token(@user.id, @user.role_authorization),
                  message: 'User signed in' }.to_json
    else
      halt 401, { error: 'Login credentials are not valid' }.to_json
    end
  end

  def token(user_id, scopes)
    JWT.encode access_payload(user_id, scopes), ENV['JWT_SECRET'], 'HS256'
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
end