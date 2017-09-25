require 'bcrypt'

# .nodoc. #
class User < ActiveRecord::Base
  include BCrypt
  validates_uniqueness_of :email, :username
  validates_presence_of :email, :username, :password_hash
  enum role: [:admin, :free, :premium]

  def initialize(arg = {})
    super
    self.role ||= 'free'
  end

  def password
    @password ||= BCrypt::Password.new(password_hash)
  end

  def password=(new_password)
    self.password_hash = BCrypt::Password.create(new_password)
  end

  def role_authorization
    if self.role == User.roles('admin')
      ['admin']
    elsif self.role == User.roles('free')
      %w(view_session add_session)
    elsif self.role == User.roles('premium')
      %w(view_session add_session view_stats)
    end
  end
end
