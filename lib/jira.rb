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
  
  class Search

    SEARCH_PATH = '/rest/api/latest/search.json'
    KEYS = %w|project issuetype affectedVersion assignee|
    # if we don't have symbols here options can't be checked for search parameters
    OPTIONS = %w|startAt maxResults expand|.map{|elem| elem.to_sym}

    def self.search(opts = {})
      # The only parameter that needs escaping (future version should use an array)
      unless opts[:affectedVersion].nil?
        opts[:affectedVersion] = "%22#{opts[:affectedVersion]}%22"
      end
      query = ""
      KEYS.each do |var|
        if opts[var.to_sym]
          query << "%20AND%20" if(0 < query.length)
          query << "#{var}=#{opts[var.to_sym]}"
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
      "requesting: #{opts[:host]}#{SEARCH_PATH}?jql=#{query}" if opts[:logger].nil? && opts[:debug]

      # FIXME: if the user or password contains any characters that could break 
      # authentification, such as a colon, they will break authentification here!
      RestClient::Resource.new("#{opts[:host]}#{SEARCH_PATH}?jql=#{query}", opts[:user], opts[:pass]).get(:content_type => 'application/json')
    end
  end
end


