class AddMunicipalityToAirports < ActiveRecord::Migration[6.1]
  def up
    add_column :airports, :municipality, :string
  end

  def down
    remove_column :airports, :municipality
  end
end
