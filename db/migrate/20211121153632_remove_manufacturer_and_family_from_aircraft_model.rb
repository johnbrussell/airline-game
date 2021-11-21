class RemoveManufacturerAndFamilyFromAircraftModel < ActiveRecord::Migration[6.1]
  def up
    remove_column :aircraft_models, :manufacturer
    remove_column :aircraft_models, :family
  end

  def down
    add_column :aircraft_models, :manufacturer, :string
    add_column :aircraft_models, :family, :string
  end
end
