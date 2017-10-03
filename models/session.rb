class Session < ActiveRecord::Base
  validates_presence_of :start, :final
  validate :date_validation
  belongs_to :user, required: true

  def initialize(args = {})
    super
    begin
      self.start = Time.parse(args[:start]&.to_s).utc
      self.final = Time.parse(args[:final]&.to_s).utc
    rescue TypeError
      puts TypeError
    end
  end

  def start=(new_start)
    super(Time.parse(new_start.to_s).utc)
  end

  def final=(new_final)
    super(Time.parse(new_final.to_s).utc)
  end

  private

  def date_validation
    return if start.nil? || final.nil?
    errors.add(:time, 'session start needs to be smaller than final') if start >= final
  end
end
