class ChangeNameOfGlobalDemand < ActiveRecord::Migration[6.1]
  def up
    rename_table :global_demand, :global_demands
  end

  def down
    rename_table :global_demands, :global_demand
  end
end
