require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'dotenv/load'

class Api < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    Dotenv.load
  end
  helpers Sinatra::Helpers
  before { json_body }
end

class Public < Api
  get '/' do
    { message: 'Tomato Api' }.to_json
  end

  post '/register' do
    @user = User.new(email: @request_body[:email],
                     username: @request_body[:username],
                     password: @request_body[:password],
                     role: @request_body[:role] || nil)
    aud = request.base_url
    access_token = Token.create(user: @user,
                                grant_type: 'access_token',
                                aud: aud)
    if access_token && @user.save
      halt 200, { access_token: access_token,
                  expires_in: access_token.expiration,
                  scopes: @user.scopes,
                  token_type: 'Bearer',
                  message: 'User created' }.to_json
    else
      halt 401, { error: @user.errors.full_messages }.to_json
    end
  end

  post '/authorize' do
    @user = if email?(@request_body[:login])
              User.find_by(email: @request_body[:login])
            else
              User.find_by(username: @request_body[:login])
            end
    if @user.hash == @request_body[:password]
      aud = request.base_url
      access_token = Token.create(user: @user,
                                  grant_type: 'access_token',
                                  aud: aud)
      halt 200, { access_token: access_token,
                  expires_in: access_token.expiration,
                  scopes: @user.scopes,
                  token_type: 'Bearer',
                  message: 'User signed in' }.to_json
    else
      halt 401, { error: 'Login credentials are not valid' }.to_json
    end
  end
end

class UserController < Api
  get '/me' do
    authenticate!
    halt 200, { email: @user.email,
                username: @user.username,
                message: 'get' }.to_json
  end

  put '/me' do
    authenticate!
    if @user.update(User.public_params(@request_body))
      { user: @user.attributes, message: 'post' }.to_json
    else
      halt 401, new_session.errors.full_messages
    end
  end

  put '/me/password' do
    authenticate!
    if @user.update(@request_body)
      { user: @user.attributes, message: 'post' }.to_json
    else
      halt 401, new_session.errors.full_messages
    end
  end

  get '/:username' do
    authenticate!
    process_request request, 'view_session' do |_req|
      halt 200, { user: @user.username, message: 'get' }.to_json
    end
  end

  post '/:username/sessions/new' do
    authenticate!
    process_request request, 'add_session' do |_req|
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
end
