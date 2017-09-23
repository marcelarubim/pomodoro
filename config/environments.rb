configure :production do
  set :show_exceptions, true

  db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/pomodoro')
  ActiveRecord::Base.establish_connection(
    adapter:  db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    host:     db.host,
    username: db.user,
    password: db.password,
    database: db.path[1..-1],
    encoding: 'utf8',
    pool:     ENV['DB_POOL'] || ENV['MAX_THREADS'] || 5
  )
end

configure :development, :test do
  ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
    database: 'sqlite:///development.db',
    show_exceptions: true
  )
end
