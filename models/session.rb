class Session < ActiveRecord::Base
  validates_presence_of :start, :final
  belongs_to :user

  def initialize(args = {})
	  super
	  self.start = Time.parse(args[:start].to_s).utc
	  self.final = Time.parse(args[:final].to_s).utc
	end
end
