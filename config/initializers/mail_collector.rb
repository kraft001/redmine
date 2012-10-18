require 'rubygems'
require 'rufus/scheduler'

scheduler = Rufus::Scheduler.start_new(:frequency => 60.0)

scheduler.every '11m', :allow_overlapping => false, :first_in => '5m' do
  Mailreceiver::receive('mail_handler.yml')
end

scheduler.every '13m', :allow_overlapping => false, :first_in => '5m' do
  Mailreceiver::receive('mail_handler_help.yml')
end

scheduler.every '17m', :allow_overlapping => false, :first_in => '5m' do
  Mailreceiver::receive('mail_handler_cz.yml')
end
