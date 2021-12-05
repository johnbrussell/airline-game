class AddAirlineRoutes < ActiveRecord::Migration[6.1]
  def up
    create_table :airline_routes do |t|
      t.float :economy_price, null: false
      t.float :premium_economy_price, null: false
      t.float :business_price, null: false
      t.string :origin_airport_id, null: false
      t.string :destination_airport_id, null: false
      t.integer :distance, null: false
      
      t.timestamps
    end
  end

  def down
    drop_table :airline_routes
  end
end
