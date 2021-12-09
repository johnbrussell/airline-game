class Airline < ApplicationRecord
  validates :cash_on_hand, presence: true
  validates :name, presence: true
  validates :is_user_airline, :inclusion => { :in => [true, false] }
  validate :only_one_user_airline_exists

  private

    def only_one_user_airline_exists
      if is_user_airline && Airline.where(is_user_airline: true).count > 0
        errors.add(:is_user_airline, "cannot be true for multiple airlines")
      end
    end
end
