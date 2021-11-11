class CreateTourists < ActiveRecord::Migration[6.1]
  def up
    create_table :tourists do |t|
      t.belongs_to :market
      t.integer :volume, null: false
      t.integer :year, null: false

      t.timestamps
    end
  end

  def down
    drop_table :tourists
  end
end
