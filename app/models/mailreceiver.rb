class Mailreceiver
  def self.receive(config_file)
    emails = YAML::load(open("#{RAILS_ROOT}/config/#{config_file}"))[RAILS_ENV]
    emails.each do |email, cfg|
      puts "#{email} handling..."
      protocol_options = {
        :general => cfg.pick(*%w(host port username password)),
        :imap => cfg.pick(*%w(ssl folder move_on_success move_on_failure)),
        :pop3 => cfg.pick(*%w(delete_unprocessed apop))
      }
      options = cfg.pick(*%w(allow_override unknown_user no_permission_check)).symbolize_keys
      options[:issue] = cfg.pick(*%w(project status tracker category priority mail_from assigned_to)).symbolize_keys

      begin
        if %w(imap pop3).include?(cfg['protocol'])
          connection_options =
            protocol_options[:general].
            merge(protocol_options[cfg['protocol'].to_sym]).
            symbolize_keys
          klass = "Redmine::#{cfg['protocol'].upcase}".constantize
          klass.check(connection_options, options)
        else
          MailHandler.receive(STDIN.read, options)
        end
      rescue Exception => e
        puts "Error: #{e.message}"
      end
    end
  end
end
