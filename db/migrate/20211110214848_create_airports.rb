class CreateAirports < ActiveRecord::Migration[6.1]
  def up
    create_table :airports do |t|
      t.belongs_to :market
      t.string :iata, null: false
      t.float :exclusive_catchment, null: false, default: 0
      t.integer :runway, null: false
      t.integer :elevation, null: false
      t.integer :start_gates, null: false
      t.integer :easy_gates, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false

      t.timestamps
    end
  end

  def down
    drop_table :airports
  end
end
