require_relative '../lib/item'

require_relative '../lib/logger_manager'

require_relative '../lib/item_collection'

require_relative '../lib/item_container'

require 'json'

require 'yaml'

require 'csv'

require 'fileutils'

module MyApplication
  class TestItemCollection
    def self.run_tests
      collection = ItemCollection.new

      collection.generate_test_items(10)

      raise "Expected 10 items, got #{collection.items.size}" unless collection.items.size == 10

      puts "Test 1 Passed: Items added successfully. Count: #{collection.items.size}"

      begin

        collection.save_to_file

        puts 'Test 2 Passed: Items saved to TXT successfully.'

        collection.save_to_json

        puts 'Test 3 Passed: Items saved to JSON successfully.'

        collection.save_to_csv

        puts 'Test 3 Passed: Items saved to CSV successfully.'

        collection.save_to_yml

        puts 'Test 4 Passed: Items saved to YAML successfully.'

        new_item = Item.generate_fake

        collection.add_item(new_item)

        raise 'Failed to add item.' unless collection.items.last == new_item

        puts 'Test 6 Passed: Item added successfully.'

        collection.remove_item(new_item)

        raise 'Failed to remove item.' if collection.items.include?(new_item)

        puts 'Test 7 Passed: Item removed successfully.'

        total_price = collection.total_price

        raise 'Expected total price to be greater than 0.' unless total_price > 0

        puts "Test 8 Passed: Total price calculated correctly. Total: #{total_price}"

        if collection.all_expensive?(5)

          puts 'Test 9 Passed: All items are above price limit.'

        else

          puts 'Test 9 Failed: Not all items are above price limit.'

        end

        raise 'Failed: No items above price limit.' unless collection.any_expensive?(5)

        puts 'Test 10 Passed: At least one item is above price limit.'

        raise 'Failed: Some items are below price limit.' unless collection.none_cheap?(1)

        puts 'Test 11 Passed: No items are below price limit.'

        category = collection.items.first.category

        count_in_category = collection.count_in_category(category)

        puts "Test 12 Passed: Items counted in category '#{category}': #{count_in_category}"

        sorted_items = collection.sort_by_price

        raise 'Failed to sort items by price.' unless sorted_items == collection.items.sort_by(&:price)

        puts 'Test 13 Passed: Items sorted by price successfully.'

        unique_categories = collection.unique_categories

        raise 'Failed to identify unique categories.' unless unique_categories == collection.items.map(&:category).uniq

        puts 'Test 14 Passed: Unique categories identified successfully.'

        collection.generate_test_items(5)

        collection.delete_items

        raise 'Failed to delete all items from collection' unless collection.items.empty?

        puts 'Test 15 Passed: All items deleted from collection.'

        transformed_names = collection.transform_items { |item| item.name.upcase }

        raise 'Failed to transform items.' unless transformed_names == collection.items.map { |item| item.name.upcase }

        puts 'Test 16 Passed: Items transformed successfully.'

        collection.generate_test_items(5)

        selected_items = collection.select_items { |item| item.price > 10 }

        raise 'Failed to select items by price.' unless selected_items.all? { |item| item.price > 10 }

        puts 'Test 17 Passed: Items selected successfully by price.'

        rejected_items = collection.reject_items { |item| item.price < 5 }

        raise 'Failed to reject items by price.' unless rejected_items.none? { |item| item.price < 5 }

        puts 'Test 18 Passed: Items rejected successfully by price.'
      rescue StandardError => e
        puts "Test failed: #{e.message}"
      end
    end
  end
end

MyApplication::TestItemCollection.run_tests
