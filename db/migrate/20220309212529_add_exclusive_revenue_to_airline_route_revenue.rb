class AddExclusiveRevenueToAirlineRouteRevenue < ActiveRecord::Migration[6.1]
  def up
    add_column :airline_route_revenues, :exclusive_revenue, :float, null: false
  end

  def down
    remove_column :airline_route_revenues, :exclusive_revenue
  end
end
