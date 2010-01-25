namespace :hoptoad do
  desc "Hoptoad's help."
  task :help => :environment do
      puts "\nExample: rake hoptoad:import hoptoad_project= project= tracker= status= author=\n\n"
      puts "hoptoad_project - Hoptoad project id (no default value)"
      puts "project - Redmine project identifier for issues create (no default value)"
      puts "tracker - Redmine tracker id (has default value)"
      puts "status - Redmine status id (has default value)"
      puts "author - Redmine user login (no default value)\n\n"

      puts "\nExample: rake hoptoad:all_resolved hoptoad_project= status= author=\n\n"
      puts "hoptoad_project - Hoptoad project id (no default value)"
      puts "status - Redmine status id (has default value)"
      puts "author - Redmine user login (default value is first admin)\n\n"
      exit
  end

  desc "Import and update Hoptoad's notifies."
  task :import => :environment do

    puts "Error: Wrong author name! (available: " + User.find(:all).collect {|u| u.login }.join("/") + ")" if !author = ENV["author"] ? (User.find_by_login(ENV["author"])) : false
    puts "Error: Wrong project identifier! (available: " + Project.find(:all).collect {|p| p.identifier }.join("/") + ")" if !project = ENV["project"] ? (Project.find_by_identifier(ENV["project"])) : false
    exit if !author || !project
    
    if !author.allowed_to?(:add_issues, project)
      puts "User #{author.login} has no permission to add issues into \"#{project.identifier}\" project"
      exit
    end
    
    default_tracker = Project.find(project).trackers.first
    tracker = default_tracker if !tracker = Tracker.find_by_id(ENV["tracker"])
    default_new_status = IssueStatus.find_by_is_default true
    status = default_new_status if !status = IssueStatus.find_by_id(ENV["status"])
    User.current = author

    puts "hoptoad project: #{ENV["hoptoad_project"]}"
    puts "project: #{project.id}"
    puts "tracker: #{tracker.id}"
    puts "status: #{status.id}"
    puts "author: #{author.login}"
    puts "permission to add issues: #{User.current.allowed_to? :add_issues, project}"

    updated = created = ignored = not_updated = 0
    page = 1
    hoptoad = Hoptoad.new

    while !(errors = hoptoad.get(ENV["hoptoad_project"], page)).root.text.nil? do
      puts "======= Page: ##{page} ======="
      errors.elements.each("*/*/id") do |x| 
        tmp = {}
        puts "Notice ##{x.text} parsing ..."
        details = hoptoad.error x.text
      
        details.elements.each do |value|
          if !tsk = Issue.first(:conditions => "subject like '%[##{value.elements["id"].text}]%'")
            if value.elements["resolved"].text == 'false'
              desc = ''
              value.elements.each {|x| desc += "**#{x.name}:** #{x.text}\n" if x.elements.empty? }
              new_issue = Issue.new(:tracker_id => tracker.id, :author_id => author.id, :project_id => project.id, :subject => "#{value.elements["error-class"].text} [##{value.elements["id"].text}]", :description => desc, :status_id => status.id)
              new_issue.save!
              puts "Issue created ..."
              created += 1
              
              value.elements.each do |x| 
                if !x.elements.empty?
                  tofile = x.elements.collect {|lines| lines.elements.empty? ? "#{lines.name}: #{lines.text}" : "#{lines.name}: {" + lines.elements.collect{|sub| "\"#{sub.name}\" => \"#{sub.text.nil? ? "" : sub.text.strip}\""}.join(", ") + "}" }.join("\n")
                  attach = File.new(Attachment.storage_path + "/" + (filename = Attachment.disk_filename(attach_file = "#{value.elements["id"].text}_#{x.name}.txt")), "a+")
                  attach.puts tofile
                  attach.close
                  puts "attaching - " + filename
                  Attachment.new(:attributes => {:container_id => new_issue.id, :container_type => "Issue",  :filename => attach_file, :disk_filename => filename, :filesize => File.stat(Attachment.storage_path + "/" + filename), :content_type => "text/txt", :author_id => author.id ,:description => x.name}).save!
                end
              end
     
            else ignored += 1
            end
          else
            if tsk.status.is_closed && value.elements["resolved"].text == 'false'
                tsk.status_id = status.id
                tsk.save!
                updated += 1
                puts "Not resolved ... updating issue ..."
            else 
                not_updated += 1
                puts "Issue already exists ..."
            end
          end
        end
      end
      page += 1
    end
    puts "\nNew issues created: #{created}"
    puts "Marked as unresolved: #{updated}" 
    puts "Not changed: #{not_updated}"
  end


  desc "Marks all errors as resolved."
  task :all_resolved => :environment do

    default_resolved_status = IssueStatus.find_by_is_closed true #or IssueStatus.first(:conditions => "is_closed = true").id    
    status = default_resolved_status if !status = IssueStatus.find_by_id(ENV["status"]) 

    if !ENV["hoptoad_project"]
      puts "Attention! you must specify hoptoad project id! (\"hoptoad_project=all\" will mark errors in all projects)"
      exit
    end
    ENV["hoptoad_project"]="" if ENV["hoptoad_project"]=="all"

    User.current = User.find_by_admin true if !User.find_by_login(ENV["author"])

    marked = 0
    page = 1
    hoptoad = Hoptoad.new
    
    while !(errors = hoptoad.get(ENV["hoptoad_project"], page, true)).root.text.nil? do
      errors.elements.each("*/*/id") do |x| 
        hoptoad.put(x.text, { :resolved => true })
        marked += 1
        if tsk = Issue.first(:conditions => "subject like '%[##{x.text}]%'")
          tsk.status_id = status.id
          if Issue.find(tsk.id).new_statuses_allowed_to(User.current).collect{|x| x.id == status.id}.include? true
            tsk.save!
          else puts "[#{status.id}] #{IssueStatus.find_by_id(status.id).name} - is not allowed status for user #{User.current.login}"
          end
        end
      end
      page += 1
    end
    puts "Marked as resolved: #{marked}"
  end


end
