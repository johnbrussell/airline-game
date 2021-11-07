require 'csv'

class GameData::Inputter < ApplicationRecord
  def self.run
    data = CSV.parse(File.read("data/metro_areas.csv"), headers: true)
    data.by_row.each do |data_point|
      Market.new(
        name: data_point["Metro Area"],
        country: data_point["Country"],
        income: data_point["Income"],
        is_national_capital: data_point["isNationalCapital"].downcase == "yes",
        is_island: data_point["isIsland"].downcase == "yes",
      ).save unless Market.exists?(name: data_point["Metro Area"])
    end
  end
end
