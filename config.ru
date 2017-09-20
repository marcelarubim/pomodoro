require 'rubygems'
require 'bundler'
require 'sinatra/base'

Bundler.require

Dir.glob('./{models,controllers}/*.rb').each { |file| require file }

# require '.controllers/'
run ApplicationController
