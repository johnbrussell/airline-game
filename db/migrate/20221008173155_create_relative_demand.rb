class CreateRelativeDemand < ActiveRecord::Migration[6.1]
  def up
    create_table :relative_demands do |t|
      t.integer :origin_market_id, null: false
      t.integer :destination_market_id, null: false
      t.string :origin_airport_iata, null: false, default: ""
      t.string :destination_airport_iata, null: false, default: ""
      t.index [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata], unique: true, name: "index_relative_demand_for_uniqueness_between_airports"

      t.float :business, null: false
      t.float :government, null: false
      t.float :leisure, null: false
      t.float :tourist, null: false

      t.float :pct_economy, null: false
      t.float :pct_premium_economy, null: false
      t.float :pct_business, null: false

      t.date :last_measured, null: false

      t.timestamps
    end
  end

  def down
    drop_table :relative_demands
  end
end
