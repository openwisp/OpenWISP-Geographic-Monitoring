class AddOwmwInfoToWisp < ActiveRecord::Migration
  def self.up
    if DATA_FROM[:owm]
      sql = <<-eos
        ALTER VIEW wisps AS
          SELECT id, name, notes, created_at, updated_at, owmw_url, owmw_username, owmw_password
          FROM owm.wisps
      eos
      execute sql
    elsif DATA_FROM[:table]
      add_column :wisps, :owmw_url, :string
      add_column :wisps, :owmw_username, :string
      add_column :wisps, :owmw_password, :string
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end

  def self.down
    if DATA_FROM[:owm]
      sql = <<-eos
        ALTER VIEW wisps AS
          SELECT id, name, notes, created_at, updated_at
          FROM owm.wisps
      eos
      execute sql
    elsif DATA_FROM[:table]
      remove_column :wisps, :owmw_url
      remove_column :wisps, :owmw_username
      remove_column :wisps, :owmw_password
    else
      raise "Either DATA_FROM[:table] or DATA_FROM[:owm] must be set to true"
    end
  end
end
