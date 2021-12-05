class AddRouteFrequencyTiers < ActiveRecord::Migration[6.1]
  def up
    create_table :frequency_tiers do |t|
      t.belongs_to :airline_route

      t.integer :seats, null: false
      t.float :passengers, null: false
      t.string :class_of_service, null: false
      t.float :reputation

      t.timestamps
    end
  end

  def down
    drop_table :frequency_tiers
  end
end
