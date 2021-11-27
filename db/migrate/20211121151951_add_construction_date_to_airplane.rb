class AddConstructionDateToAirplane < ActiveRecord::Migration[6.1]
  def up
    add_column :airplanes, :construction_date, :date, null: false
  end

  def down
    remove_column :airplanes, :construction_date
  end
end
