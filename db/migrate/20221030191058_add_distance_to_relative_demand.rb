class AddDistanceToRelativeDemand < ActiveRecord::Migration[6.1]
  def up
    add_column :relative_demands, :distance, :float, null: false
    remove_column :relative_demands, :pct_business
    remove_column :relative_demands, :pct_economy
    remove_column :relative_demands, :pct_premium_economy
  end

  def down
    add_column :relative_demands, :pct_business, :float, null: false
    add_column :relative_demands, :pct_economy, :float, null: false
    add_column :relative_demands, :pct_premium_economy, :float, null: false
    remove_column :relative_demands, :distance
  end
end
