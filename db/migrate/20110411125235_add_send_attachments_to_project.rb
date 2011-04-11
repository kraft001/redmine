class AddSendAttachmentsToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :send_attachments, :boolean, :default => false
  end

  def self.down
    remove_column :projects, :send_attachments
  end
end

