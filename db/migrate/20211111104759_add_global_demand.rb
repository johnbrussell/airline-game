class AddGlobalDemand < ActiveRecord::Migration[6.1]
  def up
    create_table :global_demand do |t|
      t.belongs_to :market
      t.date :date, null: false
      t.integer :business, null: false, :limit => 8
      t.integer :leisure, null: false, :limit => 8

      t.timestamps
    end
  end

  def down
    drop_table :global_demand
  end
end
