require "rails_helper"

RSpec.describe RelativeDemand do
  context "uniqueness validations" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Hartford") }
    let(:market_3) { Fabricate(:market, name: "Pittsburgh") }

    it "enforce uniqueness" do
      shared_inputs = {
        business: 1,
        government: 1,
        leisure: 1,
        tourist: 1,
        pct_economy: 1,
        pct_premium_economy: 1,
        pct_business: 1,
        last_measured: Date.today,
      }

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, **shared_inputs).save).to be false

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, origin_airport_iata: "INU", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, origin_airport_iata: "INU", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, origin_airport_iata: "INU", **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", **shared_inputs).save).to be false

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", **shared_inputs).save).to be false

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, destination_airport_iata: "FUN", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, destination_airport_iata: "FUN", **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", **shared_inputs).save).to be false
    end

    it "has nil origin_airport and destination_airport when they are not specified" do
      shared_inputs = {
        business: 1,
        government: 1,
        leisure: 1,
        tourist: 1,
        pct_economy: 1,
        pct_premium_economy: 1,
        pct_business: 1,
        last_measured: Date.today,
      }
      subject = RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, **shared_inputs)
      expect(subject.origin_airport).to be nil
      expect(subject.destination_airport).to be nil
    end
  end
end
