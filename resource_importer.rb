#!/usr/bin/env ruby

require 'open-uri'
require 'Nokogiri'
require 'pry'
require 'reverse_markdown'
require 'json'
require 'net/http'

config_file = File.open("config.json", "rb")
config = JSON.parse(config_file.read)
config_file.close
config['guru_url'] = "https://api.getguru.com/api"

if File.exist?("cards.json") then
  card_file = File.open("cards.json", "rb")
  card_data = JSON.parse(card_file.read)
  card_file.close
else
  card_data = {}
end

#pull all data from docs.chef.io and convert into a hash
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
    "tags" => config['tags'],
    "verifiers" => [{
      "user" => {
        "email" => "tcate@chef.io"
      },
      "type" => "user"
    }]
  }
end

def post_card (config, content)
  uri = URI("#{config['guru_url']}/v1/cards/extended")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
  request.basic_auth(config['api_user'], config['api_key'])
  request.body = content.to_json
  puts "posting data"
  response = http.request(request)
  puts response.code
  response.body.force_encoding('UTF-8')
  return response.body
end

def update_card (config, content, id)
  return content
end

def flush_to_disk (card_data)
  #Flush to disk often so you don't lose updates when errors happen
  puts "writing data"
  card_file = File.open("cards.json", "wb")
  card_file.write(card_data.to_json)
  card_file.close
end

resources.each do | resource, content |

  data = 
  #check if we've seen this card before
  if card_data.key?(content['preferredPhrase']) then
    puts "we have seen this card"
    #has the content changed since last time we've seen it?
    if !card_data[content['preferredPhrase']]['content'].eql?(content['content']) then
      puts "card has chaged updating card"
      binding.pry
      card_data[content['preferredPhrase']] = update_card(config, content, card_data[content['preferredPhrase']]['id'])
      flush_to_disk(card_data)
    else
      puts "card has not changed"
    end
  else
    puts "new card"
    card_data[content['preferredPhrase']] = JSON.parse(post_card(config, content))
    flush_to_disk(card_data)
  end
end



exit




