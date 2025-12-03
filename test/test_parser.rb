require 'mechanize'
require 'yaml'
require_relative '../lib/simple_website_parser'
require_relative '../lib/item_collection'

def test_start_parse
  config_file_path = 'config/web_parser.yaml'
  item_collection = MyApplication::ItemCollection.new
  parser = MyApplication::SimpleWebsiteParser.new(config_file_path, item_collection)

  parser.start_parse
end

test_start_parse
