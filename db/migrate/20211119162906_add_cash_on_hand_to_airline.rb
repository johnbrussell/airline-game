class AddCashOnHandToAirline < ActiveRecord::Migration[6.1]
  def up
    add_column :airlines, :cash_on_hand, :float, null: false
  end

  def down
    remove_column :airlines, :cash_on_hand
  end
end
