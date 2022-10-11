class Calculation::ClassOfService
  BUSINESS_MAX_DISTANCE = 4000
  MAX_RELATIVE_BUSINESS_DOLLARS_BUSINESS = 2.0
  MAX_RELATIVE_BUSINESS_DOLLARS_LEISURE = 0.5
  MAX_RELATIVE_PREMIUM_ECONOMY_DEMAND_BUSINESS = 0.75
  MAX_RELATIVE_PREMIUM_ECONOMY_DEMAND_LEISURE = 0.25
  PREMIUM_ECONOMY_MAX_DISTANCE = 1625

  def initialize(distance)
    @distance = distance
  end

  def pct_business_dollars_business
    ratio_business_dollars_business / ratio_sum_business
  end

  def pct_business_dollars_economy
    ratio_business_dollars_economy / ratio_sum_business
  end

  def pct_business_dollars_premium_economy
    ratio_business_dollars_premium_economy / ratio_sum_business
  end

  def pct_leisure_dollars_business
    ratio_leisure_dollars_business / ratio_sum_leisure
  end

  def pct_leisure_dollars_economy
    ratio_leisure_dollars_economy / ratio_sum_leisure
  end

  def pct_leisure_dollars_premium_economy
    ratio_leisure_dollars_premium_economy / ratio_sum_leisure
  end

  private

    def business_distance
      [BUSINESS_MAX_DISTANCE, @distance].min
    end

    def premium_economy_distance
      [PREMIUM_ECONOMY_MAX_DISTANCE, @distance].min
    end

    def ratio_business_dollars_business
      MAX_RELATIVE_BUSINESS_DOLLARS_BUSINESS * business_distance / BUSINESS_MAX_DISTANCE
    end

    def ratio_business_dollars_economy
      1
    end

    def ratio_business_dollars_premium_economy
      MAX_RELATIVE_PREMIUM_ECONOMY_DEMAND_BUSINESS * premium_economy_distance / PREMIUM_ECONOMY_MAX_DISTANCE
    end

    def ratio_leisure_dollars_business
      MAX_RELATIVE_BUSINESS_DOLLARS_LEISURE * business_distance / BUSINESS_MAX_DISTANCE
    end

    def ratio_leisure_dollars_economy
      1
    end

    def ratio_leisure_dollars_premium_economy
      MAX_RELATIVE_PREMIUM_ECONOMY_DEMAND_LEISURE * premium_economy_distance / PREMIUM_ECONOMY_MAX_DISTANCE
    end

    def ratio_sum_business
      ratio_business_dollars_business + ratio_business_dollars_premium_economy + ratio_business_dollars_economy
    end

    def ratio_sum_leisure
      ratio_leisure_dollars_business + ratio_leisure_dollars_premium_economy + ratio_leisure_dollars_economy
    end
end
