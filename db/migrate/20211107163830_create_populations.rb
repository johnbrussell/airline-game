class CreatePopulations < ActiveRecord::Migration[6.1]
  def up
    create_table :populations do |t|
      t.belongs_to :market
      t.integer :population, null: false
      t.integer :year, null: false

      t.timestamps
    end
  end

  def down
    drop_table :populations
  end
end
