ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler'

Bundler.require

# Dir.glob('./app/{models,controllers}/*.rb').each { |file| require file }
require './application'
Dir.glob('./{helpers,models}/*.rb').each { |file| require file }

run Rack::URLMap.new(
  '/' => Public,
  '/users' => UserController
)
