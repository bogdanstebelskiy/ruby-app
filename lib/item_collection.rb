require_relative 'item_container'
require_relative 'item'
require_relative 'logger_manager'
require 'json'
require 'csv'
require 'yaml'

module MyApplication
  class ItemCollection
    include ItemContainer
    include Enumerable

    attr_accessor :items
    attr_reader :base_dir

    def initialize(base_dir = File.join('output'))
      @items = []
      @base_dir = base_dir

      LoggerManager.initialize_logger('config/logging.yaml')
      LoggerManager.logger.info('Initialized ItemCollection')

      create_directory
    end

    def create_directory
      FileUtils.mkdir_p(@base_dir) unless Dir.exist?(@base_dir)
      LoggerManager.logger.info("Directory created at: #{@base_dir}")
    end

    def each(&block)
      @items.each(&block)
    end

    def generate_test_items(count = 10)
      count.times do
        add_item(Item.generate_fake)
      end
      LoggerManager.logger.info("Generated #{count} test items")
    end

    def save_to_file(filename = 'items.txt')
      filepath = File.join(@base_dir, filename)

      File.open(filepath, 'w') do |file|
        @items.each { |item| file.puts item.to_s }
      end

      LoggerManager.logger.info("Saved items to text file: #{filepath}")
    end

    def save_to_json(filename = 'items.json')
      filepath = File.join(@base_dir, filename)
      File.write(filepath, JSON.pretty_generate(@items.map(&:to_h)))
      LoggerManager.logger.info("Saved items to JSON file: #{filepath}")
    end

    def save_to_csv(filename = 'items.csv')
      filepath = File.join(@base_dir, filename)

      CSV.open(filepath, 'w') do |csv|
        csv << @items.first.to_h.keys if @items.any?
        @items.each { |item| csv << item.to_h.values }
      end

      LoggerManager.logger.info("Saved items to CSV file: #{filepath}")
    end

    def save_to_yml
      base_dir = File.join('config', 'products')
      FileUtils.mkdir_p(base_dir) unless Dir.exist?(base_dir)

      @items.group_by(&:category).each do |category, items|
        category_dir = File.join(base_dir, category)
        FileUtils.mkdir_p(category_dir) unless Dir.exist?(category_dir)

        items.each_with_index do |item, index|
          filename = "item_#{index + 1}.yml"
          filepath = File.join(category_dir, filename)

          File.write(filepath, item.to_h.to_yaml)

          LoggerManager.logger.info("Saved item to YAML file: #{filepath}")
        end
      end
    end

    def transform_items(&block)
      LoggerManager.logger.info('Transforming items in the collection')
      map(&block)
    end

    def select_items(&block)
      LoggerManager.logger.info('Selecting items based on the given condition')
      select(&block)
    end

    def reject_items(&block)
      LoggerManager.logger.info('Rejecting items based on the given condition')
      reject(&block)
    end

    def find_item(&block)
      LoggerManager.logger.info('Finding first item that meets the condition')
      find(&block)
    end

    def total_price
      total = reduce(0) { |sum, item| sum + item.price }
      LoggerManager.logger.info("Total price calculated: #{total}")
      total
    end

    def all_expensive?(price_limit)
      result = all? { |item| item.price > price_limit }
      LoggerManager.logger.info("Checking if all items are above price limit #{price_limit}: #{result}")
      result
    end

    def any_expensive?(price_limit)
      result = any? { |item| item.price > price_limit }
      LoggerManager.logger.info("Checking if any item is above price limit #{price_limit}: #{result}")
      result
    end

    def none_cheap?(price_limit)
      result = none? { |item| item.price < price_limit }
      LoggerManager.logger.info("Checking if no items are below price limit #{price_limit}: #{result}")
      result
    end

    def count_in_category(category)
      count = count { |item| item.category == category }
      LoggerManager.logger.info("Counted items in category '#{category}': #{count}")
      count
    end

    def sort_by_price
      sorted_items = sort_by(&:price)
      LoggerManager.logger.info('Items sorted by price successfully')
      sorted_items
    end

    def unique_categories
      categories = map(&:category).uniq
      LoggerManager.logger.info("Unique categories identified: #{categories}")
      categories
    end
  end
end
