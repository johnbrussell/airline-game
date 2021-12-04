class Calculation::DemandCurve
  PERCENT_ISLAND_NORMAL = Calculation::MarketDollars::PERCENT_INCOME_SPENT_ON_TRAVEL.to_f / \
    (Calculation::MarketDollars::PERCENT_INCOME_SPENT_ON_TRAVEL + Calculation::MarketDollars::PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND)
  SHORT_CONSTANTS = { :business => 1.3223140496, :leisure => 1.5625 }
  SHORT_EXPONENTS = { :business => 2, :leisure => 3 }
  SHORT_SIGNIFICANCES = { :business => 10 ** -3, :leisure => 10 ** -6 }
  SHORT_THRESHOLD_DISTANCES = { :business => 275, :leisure => 400 }
  LONG_THRESHOLD_DISTANCES = { :business => 400, :leisure => 600 }

  def initialize(curve_type)
    @curve_type = curve_type
  end

  def relative_demand(distance)
    if distance < short_threshold_distance
      short(distance)
    elsif distance > long_threshold_distance
      long(distance)
    else
      moderate
    end
  end

  def relative_demand_island(distance)
    (1 - PERCENT_ISLAND_NORMAL) * relative_demand_island_additional_travel(distance) + PERCENT_ISLAND_NORMAL * relative_demand(distance)
  end

  private

    def long(distance)
      long_threshold_distance * 100 / distance
    end

    def long_threshold_distance
      @long_threshold_distance ||= LONG_THRESHOLD_DISTANCES.fetch(@curve_type)
    end

    def moderate
      100
    end

    def relative_demand_island_additional_travel(distance)
      [
        (short_threshold_distance / distance) ** 2,
        short_threshold_distance / distance,
      ].min * 100
    end

    def short(distance)
      short_constant * (distance ** short_exponent) * short_significance
    end

    def short_constant
      @short_constant ||= SHORT_CONSTANTS.fetch(@curve_type)
    end

    def short_exponent
      @short_exponent ||= SHORT_EXPONENTS.fetch(@curve_type)
    end

    def short_significance
      @short_significance ||= SHORT_SIGNIFICANCES.fetch(@curve_type)
    end

    def short_threshold_distance
      @short_threshold_distance ||= SHORT_THRESHOLD_DISTANCES.fetch(@curve_type)
    end
end
