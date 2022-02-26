class CreateAirlineRouteRevenue < ActiveRecord::Migration[6.1]
  def up
    create_table :airline_route_revenues do |t|
      t.belongs_to :airline_route

      t.float :revenue, null: false
      t.float :economy_pax, null: false
      t.float :premium_economy_pax, null: false
      t.float :business_pax, null: false

      t.timestamps
    end
  end

  def down
    drop_table :airline_route_revenues
  end
end
