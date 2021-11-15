class AddCountryGroupToMarket < ActiveRecord::Migration[6.1]
  def up
    add_column :markets, :country_group, :string, null: false
  end

  def down
    remove_column :markets, :country_group
  end
end
