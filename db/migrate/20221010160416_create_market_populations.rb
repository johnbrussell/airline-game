class CreateMarketPopulations < ActiveRecord::Migration[6.1]
  def up
    create_table :market_populations do |t|
      t.belongs_to :market

      t.integer :year, null: false
      t.float :government, null: false
      t.float :population, null: false
      t.float :tourists, null: false

      t.timestamps
    end
  end

  def down
    drop_table :market_populations
  end
end
