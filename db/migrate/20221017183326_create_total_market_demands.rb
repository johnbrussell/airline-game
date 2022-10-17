class CreateTotalMarketDemands < ActiveRecord::Migration[6.1]
  def up
    create_table :total_market_demands do |t|
      t.belongs_to :market
      t.integer :year, null: false
      t.index [:market_id, :year], unique: true, name: "index_total_market_demand_on_market_and_year"

      t.integer :business, null: false, :limit => 8
      t.integer :government, null: false, :limit => 8
      t.integer :leisure, null: false, :limit => 8
      t.integer :tourist, null: false, :limit => 8

      t.timestamps
    end
  end

  def down
    drop_table :total_market_demands
  end
end
