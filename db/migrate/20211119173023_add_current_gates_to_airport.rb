class AddCurrentGatesToAirport < ActiveRecord::Migration[6.1]
  def up
    add_column :airports, :current_gates, :integer, null: false
  end

  def down
    remove_column :airports, :current_gates
  end
end
