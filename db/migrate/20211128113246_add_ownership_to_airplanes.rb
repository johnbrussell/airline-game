class AddOwnershipToAirplanes < ActiveRecord::Migration[6.1]
  def up
    add_column :airplanes, :owner_id, :integer
    add_column :airplanes, :lessee_id, :integer
    add_column :airplanes, :lease_expiry, :date
  end

  def down
    remove_column :airplanes, :owner_id
    remove_column :airplanes, :lessee_id
    remove_column :airplanes, :lease_expiry
  end
end
