require 'sinatra/base'
require 'mail'

class Sinatra::Base
  configure :production do |c|
    c.set :show_exceptions, true

    db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/pomodoro')

    ActiveRecord::Base.establish_connection(
      adapter:  db.scheme == 'postgres' ? 'postgresql' : db.scheme,
      host:     db.host,
      username: db.user,
      password: db.password,
      database: db.path[1..-1],
      encoding: 'utf8'
      )
  end

  configure :development, :test do |c|
    c.set :show_exceptions, true
  end

  Mail.defaults do
    delivery_method :smtp, { 
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'localhost.localdomain',
      user_name:            ENV['EMAIL_USER'],
      password:             ENV['EMAIL_PASSWORD'],
      authentication:       'plain',
      enable_starttls_auto: true  
    }
  end
end
