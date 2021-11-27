class ChangeAircraftTableNames < ActiveRecord::Migration[6.1]
  def up
    rename_table :aircraft_family, :aircraft_families
    rename_table :aircraft_manufacturing_queue, :aircraft_manufacturing_queues
  end

  def down
    rename_table :aircraft_families, :aircraft_family
    rename_table :aircraft_manufacturing_queues, :aircraft_manufacturing_queue
  end
end
