class CreateRouteDemand < ActiveRecord::Migration[6.1]
  def up
    create_table :route_demands do |t|
      t.float :business_dollars, null: false
      t.float :leisure_dollars, null: false
      t.date :date, null: false

      t.timestamps
    end
  end

  def down
    drop_table :route_demands
  end
end
