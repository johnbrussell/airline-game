class ChangeColumnsOnGlobalDemand < ActiveRecord::Migration[6.1]
  def up
    change_table :global_demands do |t|
      t.remove_references :market
      t.belongs_to :airport
    end
  end

  def down
    change_table :global_demands do |t|
      t.remove_references :airport
      t.belongs_to :market
    end
  end
end
