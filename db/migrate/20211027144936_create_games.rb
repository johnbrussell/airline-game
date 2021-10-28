class CreateGames < ActiveRecord::Migration[6.1]
  def up
    create_table :games do |t|
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end
  end

  def down
    drop_table :games
  end
end
