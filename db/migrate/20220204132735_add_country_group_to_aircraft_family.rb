class AddCountryGroupToAircraftFamily < ActiveRecord::Migration[6.1]
  def up
    add_column :aircraft_families, :country_group, :string, null: false
  end

  def down
    remove_column :aircraft_families, :country_group
  end
end
