require 'bcrypt'

class User < ActiveRecord::Base
  include BCrypt
  attr_readonly :password_hash
  validates_uniqueness_of :email, :username
  validates_presence_of :email, :username

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
