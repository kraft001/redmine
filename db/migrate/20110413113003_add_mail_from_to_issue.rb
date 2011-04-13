class AddMailFromToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :mail_from, :string
  end

  def self.down
    remove_column :issues, :mail_from
  end
end

