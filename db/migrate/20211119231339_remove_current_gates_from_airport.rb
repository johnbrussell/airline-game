class RemoveCurrentGatesFromAirport < ActiveRecord::Migration[6.1]
  def up
    remove_column :airports, :current_gates
  end

  def down
    add_column :airports, :current_gates, :integer
  end
end
