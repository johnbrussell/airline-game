class RemoveDistanceFromAirlineRoute < ActiveRecord::Migration[6.1]
  def up
    remove_column :airline_routes, :distance
  end

  def down
    add_column :airline_routes, :distance, :integer
  end
end
