class AddCurrentDateToGames < ActiveRecord::Migration[6.1]
  def up
    add_column :games, :current_date, :date, null: false
  end

  def down
    remove_column :games, :current_date, :date
  end
end
