require 'bcrypt'

# .nodoc. #
class User < ActiveRecord::Base
  include BCrypt
  validates_uniqueness_of :email, :username, case_sensitive: false
  validates_presence_of :email, :username, :password_hash
  validates :username, length: { minimum: 3 }
  validate :validate_email
  validate :validate_username
  enum role: %w[admin free premium]
  has_many :sessions

  before_validation do
    self.username ||= email
  end

  before_save do
    email.downcase!
    username.downcase!
  end

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
    if role == 'admin'
      ['admin']
    elsif role == 'free'
      %w[view_session add_session]
    elsif role == 'premium'
      %w[view_session add_session view_stats]
    end
  end

  private

  def validate_email
    return if email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
    errors[:email] << 'is not an email'
  end

  def validate_username
    return if username =~ /\A\w+\z/ || username == email
    errors[:username] << 'invalid characteres'
  end
end
