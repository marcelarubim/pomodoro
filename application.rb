require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'dotenv'

require './config/environments'
require_relative 'models/user'
require_relative 'models/session'
require_relative 'helpers'

class Api < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    Dotenv.load
  end
  helpers Sinatra::Helpers
  before { json_body }
end

class Auth < Api
  before do
    authenticate!
  end

  get '/user/:username' do
    process_request request, 'view_session', params['username'] do |_req|
      { user: @user.username, message: 'get' }.to_json
    end
  end

  post '/user/:username/sessions/new' do
    process_request request, 'add_session', params['username'] do |_req|
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

class Public < Api
  get '/' do
    { message: 'Tomato Api' }.to_json
  end

  post '/register' do
    @user = User.new(email: @request_body[:email],
                     username: @request_body[:username],
                     password: @request_body[:password],
                     role: @request_body[:role] || nil)
    token = token(@user.username, @user.role_authorization)
    if token && @user.save
      { message: 'User created',
        access_token: token,
        token_type: 'Bearer' }.to_json
    else
      halt 401, { error: @user.errors.full_messages }.to_json
    end
  end

  post '/signin' do
    @user = if @request_body[:login]&.include? '@'
              User.find_by(email: @request_body[:login])
            else
              User.find_by(username: @request_body[:login])
            end
    if @user.hash == @request_body[:password]
      halt 200, { access_token: token(@user.id, @user.role_authorization, 0),
                  # id_token: token(@user.id, @user.role_authorization, 1),
                  # refresh_token: token(@user.id, @user.role_authorization, 2),
                  token_type: 'Bearer',
                  message: 'User signed in' }.to_json
    else
      halt 401, { error: 'Login credentials are not valid' }.to_json
    end
  end
end
