require 'net/http'
require 'json'

module Redmine
    
    PROJECT_MAP = {
      "optim" => "optimization",
      "optimization" => "optimization",
      "opt" => "optimization",
      "reporting" => "reportifi",
      "reportifi" => "reportifi",
      "rpt" => "reportifi",
      "ssp" => "ssp",
      "rtb" => "rtb",
      "ui" => "ui",
      "support" => "support",
      "spend" => "spend_performance",
      "adops" => "spend_performance"
    }

    USERNAME_MAP = {
      'daniel' => 99
    }
    
    API_KEY_MAP = {
      99 => 'c51a54b3f03b0da4655768ed58d7d02e268c2b32'
    }

    PRIORITY_MAP = {
      "low" => 3,
      "normal" => 4,
      "high" => 5,
      "urgent" => 6,
      "immediate"=> 7
    }
    
    TRACKER_MAP = {
      :task => 5,
      :bug => 1,
      :story => 2,
      :support => 3
    }
    
    def get(uri,as)
      uri = URI("http://redmine.simpli.fi#{uri}")
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth API_KEY_MAP[USERNAME_MAP[as]], 'pass'

      res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }
      
      res
    end
    
    def current_summary
      page = 1
      issues = []
      
      set = JSON.parse(get("/issues.json?query_id=7&limit=100&page=#{page}",'daniel').body)
      while set["issues"].any? do
        issues += set["issues"]
        page += 1
        set = JSON.parse(get("/issues.json?query_id=7&limit=100&page=#{page}",'daniel').body)
      end
      
      issues_by_person = {}
      issues.each do |i|
        assigned_to = "none"
        assigned_to = i["assigned_to"]["name"] if i["assigned_to"]
        issues_by_person[assigned_to] ||= []
        issues_by_person[assigned_to] << i
      end

      puts "Issues:"
      puts "="*50
      issues_by_person.keys.each do |assigned_to|
        puts "Assigned to: #{assigned_to}"
        issues_by_person[assigned_to].each{|i| puts "\t#{i["id"].to_s.ljust(5)} #{("+"*(i["priority"]["id"].to_i - 2)).ljust(6)} - (#{i["status"]["name"]}) - #{i["subject"]}" }
        puts ""
      end
    end
    
    def past_week_summary
      page = 1
      issues = []
      
      set = JSON.parse(get("/issues.json?query_id=8&limit=100&page=#{page}",'jake').body)
      while set["issues"].any? do
        issues += set["issues"]
        page += 1
        set = JSON.parse(get("/issues.json?query_id=8&limit=100&page=#{page}",'jake').body)
      end
      
      issues_by_person = {}
      issues.each do |i|
        assigned_to = "none"
        assigned_to = i["assigned_to"]["name"] if i["assigned_to"]
        issues_by_person[assigned_to] ||= []
        issues_by_person[assigned_to] << i
      end

      puts "Issues:"
      puts "="*50
      issues_by_person.keys.each do |assigned_to|
        puts "Assigned to: #{assigned_to}"
        issues_by_person[assigned_to].each{|i| puts "\t#{i["id"].to_s.ljust(5)} #{("+"*(i["priority"]["id"].to_i - 2)).ljust(6)} - (#{i["status"]["name"]}) - #{i["subject"]}" }
        puts ""
      end
    end
    
    def create_issue(type,args)
      issue = {}
      issue["project_id"] = PROJECT_MAP[args[0]]
      issue["author_id"] = USERNAME_MAP[`whoami`.chomp]
      issue["subject"] = args[1]
      issue["description"] = args[2]
      issue["priority_id"] = PRIORITY_MAP[args[3] || "normal"]
      issue["tracker_id"] = TRACKER_MAP[type] || TRACKER_MAP[:bug]

      uri = URI('http://redmine.simpli.fi/issues.json')
      req = Net::HTTP::Post.new(uri.request_uri)
      req.basic_auth API_KEY_MAP[USERNAME_MAP[`whoami`.chomp]], 'pass'
      req.body = {"issue" => issue }.to_json
      req.content_type = 'application/json'

      res = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(req)
      }
      
      begin
        i = JSON.parse(res.body)
        puts "#{type} created! - http://redmine.simpli.fi/issues/#{i["issue"]["id"]}"
      rescue Exception => e
        puts "epic fail - #{e} - #{res.body}"
      end
      
    end
end
