class AircraftModelsBelongToAircraftFamilies < ActiveRecord::Migration[6.1]
  def up
    change_table :aircraft_models do |t|
      t.belongs_to :aircraft_families
    end
  end

  def down
    change_table :aircraft_models do |t|
      t.remove_references :aircraft_families
    end
  end
end
