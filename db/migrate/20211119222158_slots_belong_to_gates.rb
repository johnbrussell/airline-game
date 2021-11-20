class SlotsBelongToGates < ActiveRecord::Migration[6.1]
  def up
    change_table :slots do |t|
      t.remove_references :airport
      t.belongs_to :gates
    end
  end

  def down
    change_table :slots do |t|
      t.remove_references :gates
      t.belongs_to :airport
    end
  end
end
