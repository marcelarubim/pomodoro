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

class Public < Api
  get '/' do
    { message: 'Tomato Api' }.to_json
  end

  post '/register' do
    @user = User.new(email: @request_body[:email],
                     username: @request_body[:username],
                     password: @request_body[:password],
                     role: @request_body[:role] || nil)
    access_token = token(@user, grant_type: 'access_token')
    if access_token && @user.save
      halt 200, { access_token: access_token,
                  expires_in: ENV['ACC_TOK_EXP'],
                  scopes: @user.scopes,
                  token_type: 'Bearer',
                  message: 'User created' }.to_json
    else
      halt 401, { error: @user.errors.full_messages }.to_json
    end
  end

  post '/authorize' do
    @user = if @request_body[:login]&.include? '@'
              User.find_by(email: @request_body[:login])
            else
              User.find_by(username: @request_body[:login])
            end
    if @user.hash == @request_body[:password]
      access_token = token(@user, grant_type: 'access_token')
      halt 200, { access_token: access_token,
                  expires_in: ENV['ACC_TOK_EXP'],
                  scopes: @user.scopes,
                  token_type: 'Bearer',
                  message: 'User signed in' }.to_json
    else
      halt 401, { error: 'Login credentials are not valid' }.to_json
    end
  end
end

class UserController < Api
  get '/:username' do
    authenticate!
    process_request request, 'view_session' do |_req|
      { user: @user.username, message: 'get' }.to_json
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
