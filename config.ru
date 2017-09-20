require 'rubygems'
require 'bundler'
require 'sinatra/base'
require 'sinatra/activerecord'
require '.config/environments'

Bundler.require

Dir.glob('./{models,controllers}/*.rb').each { |file| require file }

# require '.controllers/'
run ApplicationController
