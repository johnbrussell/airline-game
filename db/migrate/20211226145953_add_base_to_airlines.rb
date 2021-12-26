class AddBaseToAirlines < ActiveRecord::Migration[6.1]
  def up
    add_column :airlines, :base_id, :integer
  end

  def down
    remove_column :airlines, :base_id
  end
end
