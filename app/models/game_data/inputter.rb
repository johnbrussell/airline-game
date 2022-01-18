require 'csv'

class GameData::Inputter < ApplicationRecord
  def self.run
    data = CSV.parse(File.read("data/metro_areas.csv"), headers: true)
    data.by_row.each do |data_point|
      self.create_or_update_market(data_point)
    end

    self.airports
    self.population
    self.tourists
    self.aircraft_models
  end

  private

    def self.aircraft_families
      data = CSV.parse(File.read("data/aircraft.csv"), headers: true)
      data.by_row.each do |data_point|
        data_map = {
          manufacturer: data_point["Manufacturer"],
          name: data_point["Family"],
        }
        if AircraftFamily.exists?(manufacturer: data_point["Manufacturer"], name: data_point["Family"])
          AircraftFamily.find_by!(manufacturer: data_point["Manufacturer"], name: data_point["Family"]).update!(**data_map)
        else
          AircraftFamily.create!(**data_map)
        end
      end
    end

    def self.aircraft_models
      self.aircraft_families
      data = CSV.parse(File.read("data/aircraft.csv"), headers: true)
      min_runway = Airport.minimum(:runway) - 1
      data.by_row.each do |data_point|
        family = AircraftFamily.find_by!(manufacturer: data_point["Manufacturer"], name: data_point["Family"])
        data_map = {
          family: family,
          name: data_point["Name"],
          production_start_year: data_point["Production Start"],
          floor_space: data_point["Square inches"],
          max_range: data_point["Range"],
          fuel_burn: data_point["Fuel burn per hour"],
          speed: data_point["Speed"],
          num_pilots: data_point["Num pilots"],
          num_flight_attendants: data_point["Num flight attendants"],
          price: data_point["Price"],
          takeoff_distance: [data_point["Takeoff length"].to_i, min_runway].max,
          useful_life: data_point["Useful life"],
        }

        if AircraftModel.exists?(name: data_point["Name"])
          AircraftModel.find_by!(name: data_point["Name"]).update!(**data_map)
        else
          AircraftModel.create!(**data_map)
        end
      end
    end

    def self.airports
      data = CSV.parse(File.read("data/airports.csv"), headers: true)
      data.by_row.each do |data_point|
        market = Market.find_by!(name: data_point["metro_area"])
        airport = Airport.find_by(iata: data_point["Airport"])
        if airport.nil?
          Airport.create!(
            market: market,
            iata: data_point["Airport"],
            exclusive_catchment: data_point["Exclusive catchment"],
            runway: data_point["Runway"],
            elevation: data_point["Elevation"],
            start_gates: data_point["Start gates"],
            easy_gates: data_point["Easy build gates"],
            latitude: data_point["Lat"],
            longitude: data_point["Long"],
          )
        else
          airport.update!(
            market: market,
            exclusive_catchment: data_point["Exclusive catchment"],
            runway: data_point["Runway"],
            elevation: data_point["Elevation"],
            start_gates: data_point["Start gates"],
            easy_gates: data_point["Easy build gates"],
            latitude: data_point["Lat"],
            longitude: data_point["Long"],
          )
        end
      end
    end

    def self.create_or_update_market(data_point)
      if Market.exists?(name: data_point["Metro Area"])
        Market.find_by(name: data_point["Metro Area"]).update!(
          country: data_point["Country"],
          country_group: data_point["Country group"],
          income: data_point["Income"],
          is_national_capital: data_point["isNationalCapital"].downcase == "yes",
          is_island: data_point["isIsland"].downcase == "yes",
        )
      else
        Market.new(
          name: data_point["Metro Area"],
          country: data_point["Country"],
          country_group: data_point["Country group"],
          income: data_point["Income"],
          is_national_capital: data_point["isNationalCapital"].downcase == "yes",
          is_island: data_point["isIsland"].downcase == "yes",
        ).save!
      end
    end

    def self.population
      Population.all.delete_all
      GlobalDemand.all.delete_all

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

    def self.tourists
      Tourists.all.delete_all
      GlobalDemand.all.delete_all

      data = CSV.parse(File.read("data/tourists.csv"), headers: true)
      data.by_row.each do |data_point|
        market = Market.find_by!(name: data_point["Metro area"])
        Tourists.create!(
          market_id: market.id,
          volume: data_point["Visitors"],
          year: data_point["Year"],
        )
      end
    end
end
