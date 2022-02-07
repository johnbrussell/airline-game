class AddTerritoryToMarket < ActiveRecord::Migration[6.1]
  def up
    add_column :markets, :territory_of, :string
  end

  def down
    remove_column :markets, :territory_of
  end
end
