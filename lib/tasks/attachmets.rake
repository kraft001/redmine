# Redmine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

namespace :redmine do
  namespace :attachments do
    task :check_lost => :environment do
      per = ENV.has_key?('per') ? ENV['per'].to_i : 1000
      num = Attachment.find(:first, :select => ('count(id) as num')).num.to_i
      all_losted = []
      (num/per).times do |i|
        losted = []
        Attachment.find(:all, :limit => [i*per, per].join(',')).each do |a|
          if a.container.nil? || !a.container.is_a?(Issue)
            puts "found ##{a.id}"
            losted << a.id
          end
        end
        all_losted += losted
        puts "[#{[i*per, (i+1)*per].join(' .. ')}] is ok!" if losted.empty?
      end
      puts "[#{all_losted.join(', ')}]"
    end

    task :max_count => :environment do
      per = ENV.has_key?('per') ? ENV['per'].to_i : 1000
      num = Issue.find(:first, :select => ('count(id) as num')).num.to_i
      issue_id = 0
      max_size = 0
      ((num/per)+1).times do |i|
        Issue.find(:all, :limit => [i*per, per].join(',')).each do |is|
          if is.attachments.size > max_size
            issue_id = is.id
            max_size = is.attachments.size
          end
        end
        puts "[#{[i*per, (i+1)*per].join(' .. ')}] max attachments count = #{max_size} in issue ##{issue_id}"
      end
    end

    task :kill_overload => :environment do
      per = ENV.has_key?('per') ? ENV['per'].to_i : 1000
      issue_id = ENV.has_key?('issue_id') ? ENV['issue_id'].to_i : 2659
      num = Attachment.find(:first, :conditions => {:container_id => issue_id}, :select => ('count(id) as num')).num.to_i
      ((num/per)+1).times do |i|
        Attachment.find(:all, :conditions => {:container_id => issue_id}, :limit => per).each do |a|
          puts "cant destroy ##{a.id}" if !a.destroy
        end
        puts "[#{[i*per, (i+1)*per].join(' .. ')}] attachments killed in issue ##{issue_id}"
      end
    end
  end
end
