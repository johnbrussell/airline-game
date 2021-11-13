class AddColumnsToGlobalDemand < ActiveRecord::Migration[6.1]
  def up
    add_column :global_demands, :tourist, :integer, null: false, :limit => 8
    add_column :global_demands, :government, :integer, null: false, :limit => 8
  end

  def down
    remove_column :global_demands, :tourist
    remove_column :global_demands, :government
  end
end
