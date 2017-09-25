require 'bcrypt'

# .nodoc. #
class User < ActiveRecord::Base
  include BCrypt
  validates_uniqueness_of :email, :username
  validates_presence_of :email, :username, :password_hash
  enum role: [:admin, :free, :premium]

  def initialize(args = {})
    super
    self.role = args[:role] || 'free'
  end

  def password
    @password ||= BCrypt::Password.new(password_hash)
  end

  def password=(new_password)
    self.password_hash = BCrypt::Password.create(new_password)
  end

  def role_authorization
    if self.role == 'admin'
      ['admin']
    elsif self.role == 'free'
      ['view_session', 'add_session']
    elsif self.role == 'premium'
      ['view_session', 'add_session', 'view_stats']
    end
  end
end
