class Game < ApplicationRecord
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :current_date, presence: true
  validate :current_date_greater_than_start_date
  validate :current_date_less_than_end_date

  has_many :airlines

  def current_date_in_words
    current_date.strftime("%B %-d, %Y")
  end

  def user_airline
    airlines.find { |a| a.is_user_airline }
  end

  private

  def current_date_greater_than_start_date
    if current_date < start_date
      errors.add(:current_date, "cannot be less than start_date")
    end
  end

  def current_date_less_than_end_date
    if current_date > end_date
      errors.add(:current_date, "cannot be greater than end_date")
    end
  end
end
