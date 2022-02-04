class AddCountryToAirplanes < ActiveRecord::Migration[6.1]
  def up
    add_column :airplanes, :base_country_group, :string, null: false
    remove_column :airplanes, :lessee_id
  end

  def down
    remove_column :airplanes, :base_country_group
    add_column :airplanes, :lessee_id, :integer
  end
end
