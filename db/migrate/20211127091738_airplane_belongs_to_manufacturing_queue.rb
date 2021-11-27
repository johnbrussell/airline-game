class AirplaneBelongsToManufacturingQueue < ActiveRecord::Migration[6.1]
  def up
    change_table :airplanes do |t|
      t.remove_references :game
      t.belongs_to :aircraft_manufacturing_queue
    end
  end

  def down
    change_table :airplanes do |t|
      t.remove_references :aircraft_manufacturing_queue
      t.belongs_to :game
    end
  end
end
