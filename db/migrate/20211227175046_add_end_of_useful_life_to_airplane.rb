class AddEndOfUsefulLifeToAirplane < ActiveRecord::Migration[6.1]
  def up
    add_column :airplanes, :end_of_useful_life, :date, null: false
  end

  def down
    remove_column :airplanes, :end_of_useful_life
  end
end
