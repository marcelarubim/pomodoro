require 'rubygems'
require 'bundler'
require 'sinatra/base'

Bundler.require

require './application_controller'
run PomodoroApp
