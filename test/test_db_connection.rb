require 'yaml'
require_relative '../lib/database_connector'
require 'logger'

config_file_path = 'config/database_config.yaml'

class Item
  attr_accessor :name, :price, :description, :category, :image_path

  def initialize(name, price, description, category, image_path)
    @name = name
    @price = price
    @description = description
    @category = category
    @image_path = image_path
  end
end

items = [
  Item.new("Item1", 100, "Description of Item1", "Category1", "path/to/image1.jpg"),
  Item.new("Item2", 200, "Description of Item2", "Category2", "path/to/image2.jpg")
]

puts "\nTesting MongoDB connection and saving data:"

mongodb_connector = MyApplication::DatabaseConnector.new(config_file_path)
mongodb_connector.connect_to_database

mongodb_connector.save_to_mongodb(items)

collection = mongodb_connector.instance_variable_get(:@db)[:items]
saved_items = collection.find.to_a

puts "\nItems saved to MongoDB:"
saved_items.each do |item|
  puts "Name: #{item[:name]}, Price: #{item[:price]}, Description: #{item[:description]}, Category: #{item[:category]}, Image Path: #{item[:image_path]}"
end

mongodb_connector.close_connection
