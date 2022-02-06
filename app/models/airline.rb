class Airline < ApplicationRecord
  validates :base_id, presence: true
  validates :cash_on_hand, presence: true
  validates :name, presence: true
  validates :is_user_airline, :inclusion => { :in => [true, false] }
  validates :game_id, presence: true
  validate :only_one_user_airline_exists

  before_destroy :validate_a_user_airline_exists

  def base
    @base ||= Market.find(base_id)
  end

  def rival_country_groups
    RivalCountryGroup
      .all
      .select { |g| g.country_one == base.country_group || g.country_two == base.country_group }
      .map { |g| [g.country_one, g.country_two].reject { |c| c == base.country_group } }
      .flatten
      .uniq
  end

  private

    def only_one_user_airline_exists
      if is_user_airline && Airline.where(is_user_airline: true, game_id: game_id).where.not(id: id).count > 0
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
