class RemoveDemandFromMarket < ActiveRecord::Migration[6.1]
  def up
    remove_column :markets, :business_demand
    remove_column :markets, :leisure_demand
  end

  def down
    add_column :markets, :business_demand, :integer, null: false, default: 0, :limit => 8
    add_column :markets, :leisure_demand, :integer, null: false, default: 0, :limit => 8
  end
end
