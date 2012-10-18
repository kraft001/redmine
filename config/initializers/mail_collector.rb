require 'rubygems'
require 'rufus/scheduler'

scheduler = Rufus::Scheduler.start_new(:frequency => 300.0)

scheduler.every '15m', :allow_overlapping => false, :first_in => '5m' do
  Mailreceiver::receive('mail_handler.yml')
  Mailreceiver::receive('mail_handler_help.yml')
  Mailreceiver::receive('mail_handler_cz.yml')
end

