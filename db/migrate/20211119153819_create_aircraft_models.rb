class CreateAircraftModels < ActiveRecord::Migration[6.1]
  def up
    create_table :aircraft_models do |t|
      t.string :manufacturer, null: false
      t.string :family, null: false
      t.string :name, null: false
      t.integer :production_start_year, null: false
      t.integer :floor_space, null: false
      t.integer :max_range, null: false
      t.integer :fuel_burn, null: false
      t.integer :speed, null: false
      t.integer :num_pilots, null: false
      t.integer :num_flight_attendants, null: false
      t.integer :price, null: false
      t.integer :takeoff_distance, null: false
      t.integer :useful_life, null: false

      t.timestamps
    end
  end

  def down
    drop_table :aircraft_models
  end
end
