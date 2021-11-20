class AddPriceToSlots < ActiveRecord::Migration[6.1]
  def up
    add_column :slots, :rent, :float, null: false, default: 0
  end

  def down
    remove_column :slots, :rent
  end
end
