class Hoptoad
  require 'yaml'
  require 'rest_client'
  require 'rexml/document'

  def initialize
    @settings = YAML::load(open("#{RAILS_ROOT}/config/hoptoad.yml"))[RAILS_ENV]["hoptoad_settings"]
  end

  def put(id, group = { :resolved => false })
     RestClient.put("http://#{@settings['account']}.hoptoadapp.com/errors/#{id}?auth_token=#{@settings['auth_token']}", :group => group)
  end

  def get(project_id, page = 1, show_resolved = false)
    show_resolved = !show_resolved ? "" : "&show_resolved=#{show_resolved}"
    xml = RestClient.get("http://#{@settings['account']}.hoptoadapp.com/errors.xml?auth_token=#{@settings['auth_token']}&page=#{page}#{show_resolved}&project_id=#{project_id}")
    REXML::Document.new(xml.gsub("<-","<").gsub("<\/-","<\/").gsub(/<[a-z,-]+\([a-z,-]+\)>/,"<error-tag>").gsub(/<\/[a-z,-]+\([a-z,-]+\)>/,"</error-tag>"))
  end

  def error(id)
    xml = RestClient.get("http://#{@settings['account']}.hoptoadapp.com/errors/#{id}.xml?auth_token=#{@settings['auth_token']}")
    REXML::Document.new(xml.gsub("<-","<").gsub("<\/-","<\/").gsub(/<[a-z0-9,-]+\([a-z0-9,-]+\)>/,"<error-tag>").gsub(/<\/[a-z0-9,-]+\([a-z0-9,-]+\)>/,"</error-tag>"))
  end

end


