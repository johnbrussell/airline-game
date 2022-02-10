class AddAirlineToAirlineRoute < ActiveRecord::Migration[6.1]
  def up
    add_column :airline_routes, :airline_id, :integer, null: false
  end

  def down
    remove_column :airline_routes, :airline_id
  end
end
