class CreateRouteDollars < ActiveRecord::Migration[6.1]
  def up
    create_table :route_dollars do |t|
      t.integer :origin_market_id, null: false
      t.integer :destination_market_id, null: false
      t.string :origin_airport_iata, null: false
      t.string :destination_airport_iata, null: false
      t.date :date, null: false
      t.index [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata, :date], unique: true, name: "index_route_dollars_for_uniqueness_between_airports"

      t.float :economy, null: false
      t.float :premium_economy, null: false
      t.float :business, null: false

      t.timestamps
    end
  end

  def down
    drop_table :route_dollars
  end
end
