class SetDefaultAirportExclusiveCatchmentTo100 < ActiveRecord::Migration[6.1]
  def up
    change_column_default :airports, :exclusive_catchment, 100.0
  end

  def down
    change_column_default :airports, :exclusive_catchment, 0.0
  end
end
