class AddNullValidationToAirlineBase < ActiveRecord::Migration[6.1]
  def up
    change_column_null :airlines, :base_id, false
  end

  def down
    change_column_null :airlines, :base_id, true
  end
end
