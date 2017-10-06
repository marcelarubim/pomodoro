ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler'

Bundler.require

# Dir.glob('./app/{models,controllers}/*.rb').each { |file| require file }
require './application'

run Rack::URLMap.new(
  '/' => Public,
  '/auth' => Auth
  '/user' => UserController
)
