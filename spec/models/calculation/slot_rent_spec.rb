require "rails_helper"

RSpec.describe Calculation::SlotRent do
  context "calculate" do
    it "calculates correctly" do
      market_mock = instance_double(Market)
      airport_mock = instance_double(Airport, market: market_mock)
      game_mock = instance_double(Game, current_date: Date.today)
      gates_mock = instance_double(Gates, airport: airport_mock, game: game_mock, current_gates: 9)
      market_dollars_mock = instance_double(Calculation::MarketDollars, business: 1000, leisure: 9000)

      expect(Gates).to receive(:at_airport).twice.with(airport_mock, game_mock).and_return(gates_mock)
      expect(Calculation::MarketDollars).to receive(:new).with(airport_mock, Date.today).and_return(market_dollars_mock)
      expect(market_mock).to receive(:airports).and_return([airport_mock])

      assert_in_epsilon described_class.calculate(airport_mock, game_mock), 900 * Calculation::SlotRent::SCALE_CONSTANT, 0.0000001
    end
  end
end
