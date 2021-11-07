require 'csv'

class GameData::Inputter < ApplicationRecord
  def self.run
    data = CSV.parse(File.read("data/metro_areas.csv"), headers: true)
    data.by_row.each do |data_point|
      self.create_or_update_market(data_point)
    end

    self.population
  end

  private

    def self.create_or_update_market(data_point)
      if Market.exists?(name: data_point["Metro Area"])
        Market.find_by(name: data_point["Metro Area"]).update!(
          country: data_point["Country"],
          income: data_point["Income"],
          is_national_capital: data_point["isNationalCapital"].downcase == "yes",
          is_island: data_point["isIsland"].downcase == "yes",
        )
      else
        Market.new(
          name: data_point["Metro Area"],
          country: data_point["Country"],
          income: data_point["Income"],
          is_national_capital: data_point["isNationalCapital"].downcase == "yes",
          is_island: data_point["isIsland"].downcase == "yes",
        ).save
      end
    end

    def self.population
      Population.all.delete_all

      data = CSV.parse(File.read("data/populations.csv"), headers: true)
      data.by_row.each do |data_point|
        market = Market.find_by!(name: data_point["Metro area"])
        Population.create!(
          market_id: market.id,
          population: data_point["Population"],
          year: data_point["Year"],
        )
      end
    end
end
