class Airline < ApplicationRecord
  validates :cash_on_hand, presence: true
  validates :name, presence: true
  validates :is_user_airline, :inclusion => { :in => [true, false] }
  validate :only_one_user_airline_exists

  before_destroy :validate_a_user_airline_exists

  private

    def only_one_user_airline_exists
      if is_user_airline && Airline.where(is_user_airline: true, game_id: game_id).count > 0
        errors.add(:is_user_airline, "cannot be true for multiple airlines within a game")
      end
    end

    def validate_a_user_airline_exists
      if is_user_airline
        errors.add(:is_user_airline, "must be true for at least one airline at all times")
        throw :abort
      end
    end
end
