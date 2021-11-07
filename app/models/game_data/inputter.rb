require 'csv'

class GameData::Inputter < ApplicationRecord
  def self.run
    data = CSV.parse(File.read("data/metro_areas.csv"), headers: true)
    data.by_row.each do |data_point|
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
  end
end
