User.create(
  username: 'user',
  email: 'email@email.com',
  password_hash: BCrypt::Password.create('password')
)
