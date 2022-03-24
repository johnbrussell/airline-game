class AddCoordinatesToMarket < ActiveRecord::Migration[6.1]
  def up
    add_column :markets, :latitude, :float
    add_column :markets, :longitude, :float
  end

  def down
    remove_column :markets, :latitude
    remove_column :markets, :longitude
  end
end
