class AddExclusiveRevenuesToAirlineRouteRevenue < ActiveRecord::Migration[6.1]
  def up
    add_column :airline_route_revenues, :exclusive_economy_revenue, :float, null: false
    add_column :airline_route_revenues, :exclusive_premium_economy_revenue, :float, null: false
    add_column :airline_route_revenues, :exclusive_business_revenue, :float, null: false
    remove_column :airline_route_revenues, :exclusive_revenue
  end

  def down
    remove_column :airline_route_revenues, :exclusive_economy_revenue
    remove_column :airline_route_revenues, :exclusive_premium_economy_revenue
    remove_column :airline_route_revenues, :exclusive_business_revenue
    add_column :airline_route_revenues, :exclusive_revenue, :float, null: false
  end
end
