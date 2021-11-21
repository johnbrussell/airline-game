class CreateAircraftManufacturingQueue < ActiveRecord::Migration[6.1]
  def up
    create_table :aircraft_manufacturing_queue do |t|
      t.belongs_to :game
      t.belongs_to :aircraft_family

      t.float :production_rate

      t.timestamps
    end
  end

  def down
    drop_table :aircraft_manufacturing_queue
  end
end
