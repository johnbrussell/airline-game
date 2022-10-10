class UpdateRelativeDemandUniquenessIndex < ActiveRecord::Migration[6.1]
  def up
    remove_index :relative_demands, name: "index_relative_demand_for_uniqueness_between_airports"
    add_index :relative_demands, [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata, :last_measured], unique: true, name: "index_relative_demand_for_uniqueness_between_airports"
  end

  def down
    remove_index :relative_demands, name: "index_relative_demand_for_uniqueness_between_airports"
    add_index :relative_demands, [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata], unique: true, name: "index_relative_demand_for_uniqueness_between_airports"
  end
end
