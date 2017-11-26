require 'sinatra/base'

module Sinatra
  module Helpers
    def email?(str)
      str.match(/\A[^@]+@[^@]+\Z/)
    end
  end
end
