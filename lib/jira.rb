=begin
Copyright (c) 2013 Dominik Elsbroek <dominik dot elsbroek at gmail>

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
=end
require 'rest_client'
require 'json'

module Jira
  
  class Fetch

    API_PREFIX = "/rest/api/2"
    PROJECT_PREFIX = "project"

    #
    # opts must contains :user, :pass, and :host
    # 
    def self.projects(opts = {})
      Jira::check_opts(opts)
      uri = "#{opts[:host]}#{API_PREFIX}/#{PROJECT_PREFIX}"
      execute_and_log_request_request(opts, uri)
    end
    
    #
    # opts must contains :project_key besides :user, :pass, and :host
    # 
    def self.project_data(opts = {})
      Jira::check_opts(opts)
      uri = "#{opts[:host]}#{API_PREFIX}/#{PROJECT_PREFIX}/#{opts[:project_key]}"
      execute_and_log_request_request(opts, uri)
    end

    #
    # opts must contains :project_key besides :user, :pass, and :host
    # 
    def self.project_versions(opts = {})
      Jira::check_opts(opts)
      uri = "#{opts[:host]}#{API_PREFIX}/#{PROJECT_PREFIX}/#{opts[:project_key]}/versions"
      uri << "?expand" if opts[:expand]
      execute_and_log_request_request(opts, uri)
    end

    #
    # opts must contains :version_id besides :user, :pass, and :host
    # 
    def self.version_data(opts = {})
      Jira::check_opts(opts)
      uri = "#{opts[:host]}#{API_PREFIX}/version/#{opts[:version_id]}"
      uri << "?expand" if opts[:expand]
      execute_and_log_request_request(opts, uri)
    end



    #
    # opts must contains :version besides :user, :pass, and :host
    # 
    def self.version(opts = {})
      Jira::check_opts(opts)
      uri = "#{opts[:host]}#{API_PREFIX}#{VERSION_PREFIX}/#{opts[:version]}"
      execute_and_log_request_request(opts, uri)
    end

    private 

    def self.execute_and_log_request_request(opts, req_path)
      opts[:logger].debug "JIRA requesting: #{req_path}" unless opts[:logger].nil?
      puts "requesting: #{req_path}" if opts[:verbose]

      # FIXME: if the user or password contains any characters that could break 
      # authentification, such as a colon, they will break authentification here!
      RestClient::Resource.new(req_path, opts[:user], opts[:pass]).get(:content_type => 'application/json')               
    end

  end

  class Search

    SEARCH_PATH = '/rest/api/latest/search.json'
    KEYS = %w|project issuetype affectedVersion fixVersion assignee|
    # if we don't have symbols here options can't be checked for search parameters
    OPTIONS = %w|startAt maxResults expand|.map {|elem| elem.to_sym}

    def self.search(opts = {})
      # The only parameter that needs escaping (future version should use an array)
      %w|affectedVersion fixVersion|.each do |esc|
        opts[esc.to_sym] = "%22#{URI.encode(opts[esc.to_sym])}%22" unless opts[esc.to_sym].nil?
      end
      query = ""
      KEYS.each do |var|
        if opts[var.to_sym]
          unless opts[var.to_sym].is_a?(Array)
            query << "%20AND%20" if(0 < query.length)
            query << "#{var}=#{opts[var.to_sym]}"
            next
          end
          query << "%20AND%20" if(0 < query.length)
          query << "("
          started_at_idx = query.length
          opts[var.to_sym].each do |elem|
            query << "%20OR%20" if(started_at_idx < query.length)
            query << "#{var}=#{elem}"
          end
          query << ")"
        end
      end
      unless (opts.keys & OPTIONS).empty?
        query << "&" if(0 < query.length)
        query_len_at_options_start = query.length
        OPTIONS.each do |var|
          if opts[var.to_sym]
            query << "%20AND%20" if(query.length < query.length)
            query << "#{var}=#{opts[var.to_sym]}"
          end
        end
      end
      opts[:logger].debug "requesting: #{opts[:host]}#{SEARCH_PATH}?jql=#{query}" unless opts[:logger].nil?
      puts "requesting: #{opts[:host]}#{SEARCH_PATH}?jql=#{query}" if opts[:logger].nil? && opts[:verbose]

      # FIXME: if the user or password contains any characters that could break 
      # authentification, such as a colon, they will break authentification here!
      RestClient::Resource.new("#{opts[:host]}#{SEARCH_PATH}?jql=#{query}", opts[:user], opts[:pass]).get(:content_type => 'application/json')
    end
  end

    
  def self.check_opts(opts)
    raise "user must not be empty" if opts[:user].nil? || opts[:user].blank? 
    raise "password must not be empty" if opts[:pass].nil? || opts[:pass].blank?
    raise "host must not be emtpy" if opts[:host].nil? || opts[:host].blank?
  end

end


