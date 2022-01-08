class AddLeaseRateToAirplanes < ActiveRecord::Migration[6.1]
  def up
    add_column :airplanes, :lease_rate, :float
  end

  def down
    remove_column :airplanes, :lease_rate
  end
end
