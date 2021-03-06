class Airline < ApplicationRecord
  validates :base_id, presence: true
  validates :cash_on_hand, presence: true
  validates :name, presence: true
  validates :is_user_airline, :inclusion => { :in => [true, false] }
  validates :game_id, presence: true
  validate :only_one_user_airline_exists

  before_destroy :validate_a_user_airline_exists

  has_many :airline_routes
  has_many :slots, foreign_key: "lessee_id"

  def self.at_airport(airport, game)
    Airline
      .joins(slots: :gates)
      .where(game_id: game.id)
      .where("gates.airport_id == ?", airport.id)
      .uniq
  end

  def base
    @base ||= Market.find(base_id)
  end

  def can_fly_between?(market_1, market_2)
    !route_is_cabotage?(market_1, market_2) && !route_is_disallowed_by_geopolitical_rivalries?(market_1, market_2)
  end

  def rival_country_groups
    RivalCountryGroup
      .all
      .select { |g| g.country_one == base.country_group || g.country_two == base.country_group }
      .map { |g| [g.country_one, g.country_two].reject { |c| c == base.country_group } }
      .flatten
      .uniq
  end

  def routes
    airline_routes
      .joins(:airplane_routes)
      .joins("LEFT OUTER JOIN airports AS origin_airports ON airline_routes.origin_airport_id == origin_airports.id")
      .joins("LEFT OUTER JOIN airports AS destination_airports ON airline_routes.destination_airport_id == destination_airports.id")
      .order("origin_airports.iata, destination_airports.iata")
      .uniq
  end

  def routes_at_airport(airport)
    airline_routes
      .joins(:airplane_routes)
      .joins("LEFT OUTER JOIN airports AS origin_airports ON airline_routes.origin_airport_id == origin_airports.id")
      .joins("LEFT OUTER JOIN airports AS destination_airports ON airline_routes.destination_airport_id == destination_airports.id")
      .where("origin_airport_id == ? OR destination_airport_id == ?", airport.id, airport.id)
      .order("origin_airports.iata, destination_airports.iata")
      .uniq
  end

  private

    def cabotage_exception_exists?(origin, destination, desired_exception_country_group)
      countries_to_consider = if origin.country == destination.country
        [origin.country, origin.territory_of].compact
      else
        [
          origin.territory_of.present? ? origin.territory_of : origin.country,
          destination.territory_of.present? ? destination.territory_of : destination.country,
        ].uniq
      end

      desired_exception_country_groups = [desired_exception_country_group, nil]

      countries_to_consider.product(desired_exception_country_groups).any? do |c, ce|
        CabotageException.where(country: c, excepted_country_group: ce).present?
      end
    end

    def route_is_cabotage?(market_1, market_2)
      base.country_group != market_1.country_group &&
        route_is_domestic?(market_1, market_2) &&
        !cabotage_exception_exists?(market_1, market_2, base.country_group)
    end

    def route_is_disallowed_by_geopolitical_rivalries?(market_1, market_2)
      RivalCountryGroup.rivals?(market_1.country_group, market_2.country_group) ||
        RivalCountryGroup.rivals?(base.country_group, market_1.country_group) ||
        RivalCountryGroup.rivals?(base.country_group, market_2.country_group)
    end

    def route_is_domestic?(market_1, market_2)
      market_1_country = market_1.territory_of.present? ? market_1.territory_of : market_1.country
      market_2_country = market_2.territory_of.present? ? market_2.territory_of : market_2.country
      market_1_country == market_2_country
    end

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
