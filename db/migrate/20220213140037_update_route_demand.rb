class UpdateRouteDemand < ActiveRecord::Migration[6.1]
  def up
    add_column :route_demands, :business, :float, null: false
    add_column :route_demands, :destination_iata, :string, null: false
    add_column :route_demands, :government, :float, null: false
    add_column :route_demands, :leisure, :float, null: false
    add_column :route_demands, :origin_iata, :string, null: false
    add_column :route_demands, :tourist, :float, null: false
    remove_column :route_demands, :business_dollars
    remove_column :route_demands, :leisure_dollars
  end

  def down
    remove_column :route_demands, :business
    remove_column :route_demands, :destination_iata
    remove_column :route_demands, :government
    remove_column :route_demands, :leisure
    remove_column :route_demands, :origin_iata
    remove_column :route_demands, :tourist
    add_column :route_demands, :business_dollars, :float, null: false
    add_column :route_demands, :leisure_dollars, :float, null: false
  end
end
