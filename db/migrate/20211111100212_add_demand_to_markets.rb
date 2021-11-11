class AddDemandToMarkets < ActiveRecord::Migration[6.1]
  def up
    add_column :markets, :business_demand, :integer, null: false, default: 0, :limit => 8
    add_column :markets, :leisure_demand, :integer, null: false, default: 0, :limit => 8
  end

  def down
    remove_column :markets, :business_demand
    remove_column :markets, :leisure_demand
  end
end
