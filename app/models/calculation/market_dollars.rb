class Calculation::MarketDollars
  DOLLARS_PER_GOVERNMENT_WORKER = 600
  DOLLARS_PER_GOVERNMENT_WORKER_ISLAND = DOLLARS_PER_GOVERNMENT_WORKER * 1.5
  DOLLARS_PER_TOURIST = 450
  DOLLARS_PER_TOURIST_ISLAND = DOLLARS_PER_TOURIST * 1.5
  PERCENT_INCOME_SPENT_ON_TRAVEL = 1
  PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_MAX = 10
  PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_CONSTANT = 1.449
  PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_EXPONENT = -0.7414
  PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_MULTIPLIER = 1432.9
  PERCENT_RESIDENT_TRAVEL_LEISURE = 88

  def initialize(airport, current_date, market = nil)
    @airport = airport
    @market = market
    @current_date = current_date
  end

  def business
    income_spent_on_business_travel
  end

  def government
    government_dollars
  end

  def leisure
    income_spent_on_leisure_travel
  end

  def tourist
    tourist_dollars
  end

  private

    def government_dollars
      if @airport.is_on_island?
        market_population.government * DOLLARS_PER_GOVERNMENT_WORKER_ISLAND
      else
        market_population.government * DOLLARS_PER_GOVERNMENT_WORKER
      end
    end

    def income_spent_on_business_travel
      market.income * percent_of_income_spent_on_business_travel * market_population.population
    end

    def income_spent_on_leisure_travel
      market.income * percent_of_income_spent_on_leisure_travel * market_population.population
    end

    def market
      @market ||= @airport.market
    end

    def market_population
      @market_population ||= MarketPopulation.calculate(market, @current_date)
    end

    def percent_of_income_spent_on_business_travel
      percent_of_income_spent_on_travel * (1 - PERCENT_RESIDENT_TRAVEL_LEISURE / 100.0)
    end

    def percent_of_income_spent_on_leisure_travel
      percent_of_income_spent_on_travel * PERCENT_RESIDENT_TRAVEL_LEISURE / 100.0
    end

    def percent_of_income_spent_on_travel
      if @airport.is_on_island?
        percent_of_income_spent_on_travel_island / 100.0
      else
        PERCENT_INCOME_SPENT_ON_TRAVEL / 100.0
      end
    end

    def percent_of_income_spent_on_travel_island
      [
        PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_MAX,
        PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_MULTIPLIER * (market_population.population ** PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_EXPONENT) + PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND_CONSTANT
      ].min
    end

    def tourist_dollars
      if @airport.is_on_island?
        market_population.tourists * DOLLARS_PER_TOURIST_ISLAND
      else
        market_population.tourists * DOLLARS_PER_TOURIST
      end
    end
end
