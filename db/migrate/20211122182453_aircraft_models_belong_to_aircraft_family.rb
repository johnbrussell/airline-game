class AircraftModelsBelongToAircraftFamily < ActiveRecord::Migration[6.1]
  def up
    change_table :aircraft_models do |t|
      t.remove_references :aircraft_families
      t.belongs_to :aircraft_family
    end
  end

  def down
    change_table :aircraft_models do |t|
      t.remove_references :aircraft_family
      t.belongs_to :aircraft_families
    end
  end
end
