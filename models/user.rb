require 'bcrypt'

class User < ActiveRecord::Base
  include BCrypt
  # attr_accessor :name, :email, :password_hash, :token
  # attr_accessor :password_hash

  def password
    @password ||= BCrypt::Password.new(password_hash)
  end

  def password=(new_password)
    self.password_hash = BCrypt::Password.create(new_password)
  end

  def generate_token!
    self.token = SecureRandom.urlsafe_base64(64)
    self.save! #persist
  end
end
