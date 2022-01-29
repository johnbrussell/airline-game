class AddNumAislesToAircraftModels < ActiveRecord::Migration[6.1]
  def up
    add_column :aircraft_models, :num_aisles, :integer, null: false, default: 1
  end

  def down
    remove_column :aircraft_models, :num_aisles
  end
end
