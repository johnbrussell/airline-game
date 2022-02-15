class MoveFromYearToDateOnDemands < ActiveRecord::Migration[6.1]
  def up
    add_column :global_demands, :year, :integer, null: false
    add_column :route_demands, :year, :integer, null: false

    remove_column :global_demands, :date
    remove_column :route_demands, :date
  end

  def down
    add_column :global_demands, :date, :date, null: false
    add_column :route_demands, :date, :date, null: false

    remove_column :global_demands, :year
    remove_column :route_demands, :year
  end
end
