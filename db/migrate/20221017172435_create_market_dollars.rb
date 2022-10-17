class CreateMarketDollars < ActiveRecord::Migration[6.1]
  def up
    create_table :market_dollars do |t|
      t.belongs_to :market
      t.integer :year, index: true
      t.index [:market_id, :year], unique: true, name: "index_market_dollars_on_market_and_year"

      t.integer :business, null: false, :limit => 8
      t.integer :government, null: false, :limit => 8
      t.integer :leisure, null: false, :limit => 8
      t.integer :tourist, null: false, :limit => 8

      t.timestamps
    end
  end

  def down
    drop_table :market_dollars
  end
end
