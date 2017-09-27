class Session < ActiveRecord::Base
  validates_presence_of :start, :final
  belongs_to :user
end
