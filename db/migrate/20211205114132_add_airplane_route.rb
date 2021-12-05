class AddAirplaneRoute < ActiveRecord::Migration[6.1]
  def up
    create_table :airplane_routes do |t|
      t.belongs_to :airline_route
      t.belongs_to :airplane

      t.integer :frequencies, null: false
      t.integer :block_time_mins, null: false
      t.float :flight_cost, null: false

      t.timestamps
    end
  end

  def down
    drop_table :airplane_routes
  end
end
