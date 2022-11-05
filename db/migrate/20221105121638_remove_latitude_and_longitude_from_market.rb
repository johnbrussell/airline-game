class RemoveLatitudeAndLongitudeFromMarket < ActiveRecord::Migration[6.1]
  def up
    remove_column :markets, :latitude
    remove_column :markets, :longitude
  end

  def down
    add_column :markets, :latitude, :float
    add_column :markets, :longitude, :float
  end
end
