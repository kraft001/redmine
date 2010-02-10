class NoSelfNotified < ActiveRecord::Migration
  def self.up
    UserPreference.all.each {|up| up.update_attributes(:others => up.others.update(:no_self_notified => true)) }
  end

  def self.down
    UserPreference.all.each {|up| up.update_attributes(:others => up.others.update(:no_self_notified => false)) }
  end
end
