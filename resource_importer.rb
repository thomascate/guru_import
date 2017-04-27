#!/usr/bin/env ruby

require 'open-uri'
require 'Nokogiri'
require 'pry'
require 'reverse_markdown'
require 'json'
require 'net/http'

config_file = File.open("config.json", "rb")
config = JSON.parse(config_file.read)
config['guru_url'] = "https://api.getguru.com/api"
page = Nokogiri::HTML(open("https://docs.chef.io/resource_examples.html"))

resources = {}
html = page.css("div.section.section").to_a.each do | node |
  markdown = ReverseMarkdown.convert(node.inner_html, github_flavored: true)
  resources[node['id']] = {
    "preferredPhrase" => "#{node['id']} resource example",
    "boards" => [{"id" => config['board_id']}],
    "collection" => {"id" => config['collection_id']},
    "content" => markdown.gsub('¶', ''),
    "verificationInterval" => 30,
    "shareStatus" => "PUBLIC",
    "verifiers" => [{
      "user" => {
        "email" => "tcate@chef.io"
      },
      "type" => "user"
    }]
  }
end

resources.each do | resource, content |

  uri = URI("#{config['guru_url']}/v1/cards/extended")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
  request.basic_auth(config['api_user'], config['api_key'])
  request.body = content.to_json
  response = http.request(request)
  puts response.code
  puts response.body

end





