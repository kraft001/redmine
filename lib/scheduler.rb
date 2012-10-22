require 'rufus/scheduler'
class Scheduler

  # Starts the scheduler unless it is already running
  def self.start_unless_running(pid_file)
    with_lockfile(File.join(File.dirname(pid_file), 'scheduler.lock')) do
      if File.exists?(pid_file)
        pid = IO.read(pid_file).to_i
        if pid > 0 && process_running?(pid)
          puts "not starting scheduler because it already is running with pid #{pid}"
        else
          puts "Process #{$$} removes stale pid file"
          File.delete pid_file
        end
      end

      if !File.exists?(pid_file)
        # Write the current PID to the file
        (File.new(pid_file,'w') << $$).close
        puts "scheduler process is: #{$$}"

        # Execute the scheduler
        new.setup_jobs
      end
      true
    end or puts "could not start scheduler - lock not acquired"
  end

  # true if the process with the given PID exists, false otherwise
  def self.process_running?(pid)
    Process.kill(0, pid)
    true
  rescue Exception
    false
  end

  # executes the given block if the lock can be acquired, otherwise nothing is
  # done and false returned.
  def self.with_lockfile(lock_file)
    lock = File.new(lock_file, 'w')
    begin
      if lock.flock(File::LOCK_EX | File::LOCK_NB)
        yield
      else
        return false
      end
    ensure
      lock.flock(File::LOCK_UN)
      File.delete lock
    end
  end

  def initialize
    @rufus_scheduler = Rufus::Scheduler.start_new
    # install exception handler to report errors via Airbrake
    @rufus_scheduler.class_eval do
      define_method :handle_exception do |job, exception|
        puts "job #{job.job_id} caught exception '#{exception}'"
        Airbrake.notify exception
      end
    end
  end

  #
  # Job-Definitions go here
  #
  def setup_jobs
    #@rufus_scheduler.every('5m') do
    #  puts "hello from your test job"
    #end
    @rufus_scheduler.every '11m', :allow_overlapping => false, :first_in => '5m' do
      Mailreceiver::receive('mail_handler.yml')
    end

    @rufus_scheduler.every '13m', :allow_overlapping => false, :first_in => '5m' do
      Mailreceiver::receive('mail_handler_help.yml')
    end

    @rufus_scheduler.every '17m', :allow_overlapping => false, :first_in => '5m' do
      Mailreceiver::receive('mail_handler_cz.yml')
    end

    puts 'scheduler initialized.'
  end

end


