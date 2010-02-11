class NoSelfNotified < ActiveRecord::Migration
  def self.up
    User.all.each do |u|
      u.pref[:no_self_notified] = true
      u.pref.save if u.save
    end
  end

  def self.down
    User.all.each do |u|
      u.pref[:no_self_notified] = false
      u.pref.save if u.save
    end
  end
end
