class CreateAirplanes < ActiveRecord::Migration[6.1]
  def up
    create_table :airplanes do |t|
      t.belongs_to :game
      t.belongs_to :aircraft_model

      t.integer :business_seats, default: 0, null: false
      t.integer :premium_economy_seats, default: 0, null: false
      t.integer :economy_seats, default: 0, null: false

      t.timestamps
    end
  end

  def down
    drop_table :airplanes
  end
end
