require 'jwt'
# .nodoc. #
class Token < ActiveRecord::Base
  validates :token, uniqueness: true, on: :save
  validates_presence_of :aud, :grant_type
  validate :revert_token_if_changed,
           if: proc { |u| u.token_changed? && !u.saved_change_to_id? },
           on: :update
  enum grant_type: %w[access_token id_token refresh_token authorization_token]

  belongs_to :user, required: true

  after_create do
    self.token = JWT.encode access_payload, ENV['JWT_SECRET'], 'HS256'
  end

  def expiration
    if access_token?
      ENV['ACC_TOK_EXP']
    elsif id_token?
      ENV['ACC_TOK_EXP']
    else
      0
    end
  end

  def self.decode(bearer)
    options = { algorithm: 'HS256',
                iss: ENV['JWT_ISSUER'],
                verify_iss: true,
                aud: ENV['JWT_AUDIENCE'],
                verify_aud: true }
    JWT.decode bearer, ENV['JWT_SECRET'], true, options
  end

  private

  def access_payload
    {
      exp: Time.now.to_i + expiration.to_i,
      iat: Time.now.to_i,
      iss: ENV['JWT_ISSUER'],
      aud: aud,
      scopes: user.scopes,
      user_id: user.id,
      token_id: id
    }
  end

  def revert_token_if_changed
    puts 'am here'
    self.token = token_was
  end
end
