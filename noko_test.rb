#!/usr/bin/env ruby

require 'open-uri'
require 'Nokogiri'
require 'pry'
require 'reverse_markdown'
require 'json'
require 'net/http'

page = Nokogiri::HTML(open("https://docs.chef.io/resource_examples.html"))


doc_links = {}
page.css('#nav-docs-list > li:nth-child(3) > ul > li:nth-child(5) > ul > li:nth-child(8) > ul > li a').each do |node|
  doc_links[node.get_attribute('title')] = "https://docs.chef.io#{node.get_attribute('href')}"
end

binding.pry