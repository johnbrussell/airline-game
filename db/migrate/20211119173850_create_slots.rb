class CreateSlots < ActiveRecord::Migration[6.1]
  def up
    create_table :slots do |t|
      t.belongs_to :airport

      t.integer :lessee_id
      t.date :lease_expiry

      t.timestamps
    end
  end

  def down
    drop_table :slots
  end
end
