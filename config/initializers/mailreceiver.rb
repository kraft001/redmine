class Mailreceiver
  include Singleton
  def self.receive(config_file)

      emails = YAML::load(open("#{RAILS_ROOT}/config/#{config_file}"))[RAILS_ENV]
      emails.each do |email, cfg|
        puts "#{email} handling..."
        protocol_options = {:host => cfg['host'],
                            :port => cfg['port'],
                            :username => cfg['username'],
                            :password => cfg['password']}

        options = { :issue => {} }
        %w(project status tracker category priority mail_from assigned_to).each { |a| options[:issue][a.to_sym] = cfg[a] if cfg[a] }
        options[:allow_override] = cfg['allow_override'] if cfg['allow_override']
        options[:unknown_user] = cfg['unknown_user'] if cfg['unknown_user']
        options[:no_permission_check] = cfg['no_permission_check'] if cfg['no_permission_check']

        begin
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
        rescue Exception => e
          puts "Error: #{e.message}"
        end
      end
    end
end