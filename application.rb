require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'dotenv'
require './config/environments'
require './models/user'
require './helper'

before do
  puts request.body.read(1)
  begin
    if request.body.read(1)
      request.body.rewind
      @request_payload = JSON.parse request.body.read, { symbolize_names: true }
    end
  rescue JSON::ParserError => e
    request.body.rewind
    puts "The body #{request.body.read} was not JSON"
  end
end

configure :development do
  register Sinatra::Reloader
  Dotenv.load
end

helpers do
  def authenticate!
    @user = User.find_by(token: request.env['USER-TOKEN'])
    halt 403 unless @user
  end
end

get '/' do
  # User.all.select('name').to_json
end

post '/login' do
  params = @request_payload[:user]
  @user = User.find_by(email: params[:email])
  if @user.password == params[:password]
    @user.generate_token!
    { token: @user.token }.to_json
  else
    halt 401
  end
end

get '/protected' do
  authenticate!
  @user.to_json
end
