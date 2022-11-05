class AddDistanceToRouteDollars < ActiveRecord::Migration[6.1]
  def up
    add_column :route_dollars, :distance, :float, null: false
  end

  def down
    remove_column :route_dollars, :distance
  end
end
