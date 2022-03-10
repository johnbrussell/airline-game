class AddExclusiveDemandsToRouteDemand < ActiveRecord::Migration[6.1]
  def up
    add_column :route_demands, :exclusive_business, :float, null: false
    add_column :route_demands, :exclusive_government, :float, null: false
    add_column :route_demands, :exclusive_leisure, :float, null: false
    add_column :route_demands, :exclusive_tourist, :float, null: false
  end

  def down
    remove_column :route_demands, :exclusive_business
    remove_column :route_demands, :exclusive_government
    remove_column :route_demands, :exclusive_leisure
    remove_column :route_demands, :exclusive_tourist
  end
end
