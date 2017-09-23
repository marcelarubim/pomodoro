require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require './config/environments'
require 'dotenv'
require 'json'
require './models/user'

before do
  content_type :json
end

configure :development do
  register Sinatra::Reloader
  Dotenv.load
end

configure :production, :development do
  enable :logging
end

get '/' do
  # 'Hello World'
  User.all.to_json
end
