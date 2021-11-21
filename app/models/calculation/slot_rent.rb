class Calculation::SlotRent
  SCALE_CONSTANT = 0.00233284737

  def self.calculate(airport, game)
    gates = Gates.at_airport(airport, game)
    SCALE_CONSTANT * (dollars_in_market(gates) ** 0.5) * (gates.current_gates ** 0.5) * (gates_in_market(gates) ** 0.5)
  end

  private

    def self.dollars_in_market(gates)
      market_dollar_calculator = Calculation::MarketDollars.new(gates.airport, gates.game.current_date)
      market_dollar_calculator.business + market_dollar_calculator.leisure
    end

    def self.gates_in_market(gates)
      market = gates.airport.market
      market.airports.flat_map { |airport| Gates.at_airport(airport, gates.game) }.sum(&:current_gates)
    end
end
