require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require './config/environments'
require 'dotenv'
require 'json'

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

# nodoc #
module Models
  autoload :User, 'app/models/user'
end
get '/' do
  'Hello World'
end
