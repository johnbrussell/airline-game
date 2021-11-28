class AddOperatorIdToAirplane < ActiveRecord::Migration[6.1]
  def up
    add_column :airplanes, :operator_id, :integer
  end

  def down
    remove_column :airplanes, :operator_id, :integer
  end
end
