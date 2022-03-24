class MakeMarketCoordinatesNonNullable < ActiveRecord::Migration[6.1]
  def up
    change_column_null :markets, :latitude, false
    change_column_null :markets, :longitude, false
  end

  def down
    change_column_null :markets, :latitude, true
    change_column_null :markets, :longitude, true
  end
end
