class Calculation::MarketDollars
  DOLLARS_PER_GOVERNMENT_WORKER = 600
  DOLLARS_PER_TOURIST = 300
  PERCENT_INCOME_SPENT_ON_TRAVEL = 1
  PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND = 10
  PERCENT_RESIDENT_TRAVEL_LEISURE = 88

  def initialize(airport, current_date)
    @airport = airport
    @current_date = current_date
  end

  def business
    government_dollars + income_spent_on_business_travel
  end

  def leisure
    tourist_dollars + income_spent_on_leisure_travel
  end

  private
    def airport_population_calculator
      @airport_population_calculator ||= Calculation::AirportPopulation.new(@airport, @current_date)
    end

    def government_dollars
      airport_population_calculator.government_workers * DOLLARS_PER_GOVERNMENT_WORKER
    end

    def income_spent_on_business_travel
      market.income * percent_of_income_spent_on_business_travel * airport_population_calculator.population
    end

    def income_spent_on_leisure_travel
      market.income * percent_of_income_spent_on_leisure_travel * airport_population_calculator.population
    end

    def market
      @market ||= @airport.market
    end

    def percent_of_income_spent_on_business_travel
      percent_of_income_spent_on_travel * (1 - PERCENT_RESIDENT_TRAVEL_LEISURE / 100.0)
    end

    def percent_of_income_spent_on_leisure_travel
      percent_of_income_spent_on_travel * PERCENT_RESIDENT_TRAVEL_LEISURE / 100.0
    end

    def percent_of_income_spent_on_travel
      if @airport.is_on_island?
        PERCENT_INCOME_SPENT_ON_TRAVEL_ISLAND / 100.0
      else
        PERCENT_INCOME_SPENT_ON_TRAVEL / 100.0
      end
    end

    def tourist_dollars
      airport_population_calculator.tourists * DOLLARS_PER_TOURIST
    end
end
