class AddCountStatsToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :count_stats, :boolean, :default => true
  end

  def self.down
    remove_column :groups, :count_stats
  end
end
