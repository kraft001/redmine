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
  namespace :email do

    desc <<-END_DESC
Read emails from an IMAP/POP3 server or STDIN.
Options:
  config=path/to/file.yml    Path to config file (default: RAILS_ROOT/config/mail_handler.yml)
Example:
  rake redmine:email:receive RAILS_ENV="production" config=config/mail_handler.yml
END_DESC

    task :receive => :environment do
      emails = YAML::load(
                 open(ENV['config'] ||
                 "#{RAILS_ROOT}/config/mail_handler.yml")
               )[RAILS_ENV]

      emails.each do |email, cfg|
        puts "#{email} handling..."
        protocol_options = {:host => cfg['host'],
                            :port => cfg['port'],
                            :username => cfg['username'],
                            :password => cfg['password']}

        options = { :issue => {} }
        %w(project status tracker category priority).each { |a| options[:issue][a.to_sym] = cfg[a] if cfg[a] }
        options[:allow_override] = cfg['allow_override'] if cfg['allow_override']
        options[:unknown_user] = cfg['unknown_user'] if cfg['unknown_user']
        options[:no_permission_check] = cfg['no_permission_check'] if cfg['no_permission_check']

        case cfg['protocol']
          when 'imap'
            protocol_options.merge!({:ssl => cfg['ssl'],
                                     :folder => cfg['folder'],
                                     :move_on_success => cfg['move_on_success'],
                                     :move_on_failure => cfg['move_on_failure']})
            Redmine::IMAP.check(protocol_options, options)
          when 'pop3'
            protocol_options.merge!({:apop => cfg['apop'],
                                     :delete_unprocessed => cfg['delete_unprocessed']})
            Redmine::POP3.check(protocol_options, options)
          else
            MailHandler.receive(STDIN.read, options)
        end
      end
    end

    desc "Send a test email to the user with the provided login name"
    task :test, :login, :needs => :environment do |task, args|
      include Redmine::I18n
      abort l(:notice_email_error, "Please include the user login to test with. Example: login=examle-login") if args[:login].blank?

      user = User.find_by_login(args[:login])
      abort l(:notice_email_error, "User #{args[:login]} not found") unless user.logged?

      ActionMailer::Base.raise_delivery_errors = true
      begin
        Mailer.deliver_test(User.current)
        puts l(:notice_email_sent, user.mail)
      rescue Exception => e
        abort l(:notice_email_error, e.message)
      end
    end
  end
end

