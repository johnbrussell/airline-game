class CreateMarkets < ActiveRecord::Migration[6.1]
  def up
    create_table :markets do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :country, null: false
      t.integer :income, null: false
      t.boolean :is_national_capital, default: false, null: false
      t.boolean :is_island, default: false, null: false

      t.timestamps
    end
  end

  def down
    drop_table :markets
  end
end
