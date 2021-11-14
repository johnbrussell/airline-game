class CreateAirlines < ActiveRecord::Migration[6.1]
  def up
    create_table :airlines do |t|
      t.string :name, null: false
      t.boolean :is_user_airline, null: false, default: false
      t.belongs_to :game
      
      t.timestamps
    end
  end

  def down
    drop_table :airlines
  end
end
