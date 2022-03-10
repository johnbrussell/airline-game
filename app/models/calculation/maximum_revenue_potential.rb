class Calculation::MaximumRevenuePotential
  include Demandable

  BUSINESS_MAX_DISTANCE = 4000
  MAX_RELATIVE_BUSINESS_DOLLARS_BUSINESS = 2.0
  MAX_RELATIVE_BUSINESS_DOLLARS_LEISURE = 0.5
  MAX_RELATIVE_PREMIUM_ECONOMY_DEMAND_BUSINESS = 0.75
  MAX_RELATIVE_PREMIUM_ECONOMY_DEMAND_LEISURE = 0.25
  PREMIUM_ECONOMY_MAX_DISTANCE = 1625
  WEEKS_PER_YEAR = 365.25 / 7

  def max_business_class_revenue_per_week
    (business_dollars_business + leisure_dollars_business) / WEEKS_PER_YEAR
  end

  def max_economy_class_revenue_per_week
    (business_dollars_economy + leisure_dollars_economy) / WEEKS_PER_YEAR
  end

  def max_exclusive_business_class_revenue_per_week
    (exclusive_business_dollars_business + exclusive_leisure_dollars_business) / WEEKS_PER_YEAR
  end

  def max_exclusive_economy_class_revenue_per_week
    (exclusive_business_dollars_economy + exclusive_leisure_dollars_economy) / WEEKS_PER_YEAR
  end

  def max_exclusive_premium_economy_class_revenue_per_week
    (exclusive_business_dollars_premium_economy + exclusive_leisure_dollars_premium_economy) / WEEKS_PER_YEAR
  end

  def max_premium_economy_class_revenue_per_week
    (business_dollars_premium_economy + leisure_dollars_premium_economy) / WEEKS_PER_YEAR
  end

  private

    def business_distance
      [BUSINESS_MAX_DISTANCE, distance].min
    end

    def business_dollars_business
      pct_business_dollars_business * total_business_dollars
    end

    def business_dollars_economy
      pct_business_dollars_economy * total_business_dollars
    end

    def business_dollars_premium_economy
      pct_business_dollars_premium_economy * total_business_dollars
    end

    def exclusive_business_dollars_business
      pct_business_dollars_business * total_exclusive_business_dollars
    end

    def exclusive_business_dollars_economy
      pct_business_dollars_economy * total_exclusive_business_dollars
    end

    def exclusive_business_dollars_premium_economy
      pct_business_dollars_premium_economy * total_exclusive_business_dollars
    end

    def exclusive_leisure_dollars_business
      pct_leisure_dollars_business * total_exclusive_leisure_dollars
    end

    def exclusive_leisure_dollars_economy
      pct_leisure_dollars_economy * total_exclusive_leisure_dollars
    end

    def exclusive_leisure_dollars_premium_economy
      pct_leisure_dollars_premium_economy * total_exclusive_leisure_dollars
    end

    def leisure_dollars_business
      pct_leisure_dollars_business * total_leisure_dollars
    end

    def leisure_dollars_economy
      pct_leisure_dollars_economy * total_leisure_dollars
    end

    def leisure_dollars_premium_economy
      pct_leisure_dollars_premium_economy * total_leisure_dollars
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

    def premium_economy_distance
      [PREMIUM_ECONOMY_MAX_DISTANCE, distance].min
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

    def route_dollars
      @route_dollars ||= Calculation::RouteDollars.new(@current_date, @origin, @destination)
    end

    def total_business_dollars
      route_dollars.business + route_dollars.government
    end

    def total_exclusive_business_dollars
      route_dollars.exclusive_business + route_dollars.exclusive_government
    end

    def total_exclusive_leisure_dollars
      route_dollars.exclusive_leisure + route_dollars.exclusive_tourist
    end

    def total_leisure_dollars
      route_dollars.leisure + route_dollars.tourist
    end
end
