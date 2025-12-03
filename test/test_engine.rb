require_relative '../lib/engine'
require_relative '../lib/item_collection'
require_relative '../lib/logger_manager'
require_relative '../lib/simple_website_parser'
require_relative '../lib/archive_sender'
require 'sqlite3'
require 'ostruct'
require 'zip'

require 'sidekiq/testing'

module MyApplication
  class TestEngine
    def initialize
      @config_file_path = 'config/config.yaml'
      @archive_name = 'output_archive.zip'
    end

    def run_tests
      engine = Engine.new(@config_file_path)

      puts "\n=== Running Engine Tests ===\n\n"

      test_config_loading(engine)

      test_logger_initialization(engine)

      engine.run(@config_file_path)

      test_save_parsed_to_csv(engine)

      test_archive_sender(engine)

      puts "\n=== Tests Completed ===\n"
    end

    private

    def test_config_loading(engine)
      puts 'Test 1: Configuration Loading'

      config = engine.config

      if config.empty?
        puts '❌ Failed: Configuration is empty'
      else
        puts '✅ Success: Configuration loaded successfully'
        puts "   Config contents: #{config}"
      end

      puts "\n"
    end

    def test_logger_initialization(engine)
      puts 'Test 2: Logger Initialization'

      begin
        engine.initialize_logger

        if engine.logger
          puts '✅ Success: Logger initialized successfully'
        else
          puts '❌ Failed: Logger is nil after initialization'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during logger initialization'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_website_parser(engine)
      puts 'Test 3: Website Parser'

      begin
        if engine.config['run_website_parser'] == 1
          engine.run_website_parser

          if engine.item_collection.items.any?
            puts '✅ Success: Website parsed successfully'
            puts "   Items parsed: #{engine.item_collection.items.count}"
          else
            puts '❌ Failed: No items were parsed'
          end
        else
          puts '⚠️ Skipped: Website parser not enabled in config'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during website parsing'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_save_parsed_to_csv(engine)
      puts 'Test 4: Save Parsed Data to CSV'

      if engine.item_collection.items.empty?
        puts '⚠️ Skipped: No parsed data available to save'
        return
      end

      begin
        if engine.config['run_save_to_csv'] == 1
          engine.run_save_to_csv

          csv_file_path = File.join(engine.item_collection.base_dir, 'items.csv')

          if File.exist?(csv_file_path) && !File.read(csv_file_path).empty?
            puts '✅ Success: Parsed data saved to CSV successfully'
            puts "   CSV file size: #{File.size(csv_file_path)} bytes"
          else
            puts "Current directory: #{Dir.pwd}"
            puts "Expected CSV path: #{csv_file_path}"
            puts '❌ Failed: CSV file was not created or is empty'
          end
        else
          puts '⚠️ Skipped: CSV save not enabled in config'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during CSV save'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_save_to_json(engine)
      puts 'Test 5: Save Parsed Data to JSON'

      if engine.item_collection.items.empty?
        puts '⚠️ Skipped: No parsed data available to save'
        return
      end

      begin
        if engine.config['run_save_to_json'] == 1
          engine.run_save_to_json

          json_file_path = File.join(engine.item_collection.base_dir, 'items.json')

          if File.exist?(json_file_path) && !File.read(json_file_path).empty?
            puts '✅ Success: Parsed data saved to JSON successfully'
            puts "   JSON file size: #{File.size(json_file_path)} bytes"
          else
            puts "Current directory: #{Dir.pwd}"
            puts "Expected JSON path: #{json_file_path}"
            puts '❌ Failed: JSON file was not created or is empty'
          end
        else
          puts '⚠️ Skipped: JSON save not enabled in config'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during JSON save'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_save_to_yaml(engine)
      puts 'Test 6: Save to YAML'

      if engine.item_collection.items.empty?
        puts '⚠️ Skipped: No parsed data available to save'
        return
      end

      begin
        if engine.config['run_save_to_yaml'] == 1
          engine.run_save_to_yaml

          all_files_saved = true

          engine.item_collection.items.each_with_index do |_item, index|
            yml_file_path = File.join(engine.item_collection.base_dir, "item_#{index + 1}.yml")

            if File.exist?(yml_file_path) && !File.read(yml_file_path).empty?
              puts "✅ Success: item_#{index + 1}.yml created successfully"
            else
              puts "❌ Failed: item_#{index + 1}.yml was not created or is empty"
              all_files_saved = false
            end
          end

          if all_files_saved
            puts '✅ All items were successfully saved to YAML files'
          else
            puts '❌ Some items failed to save to YAML'
          end
        else
          puts '⚠️ Skipped: YAML save not enabled in config'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during YAML save'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_save_to_sqlite(engine)
      puts 'Test 7: Save to SQLite'

      begin
        if engine.config['run_save_to_sqlite'] == 1
          engine.connect_to_database

          if engine.database_connector.nil?
            puts '❌ Failed: Database connection not established.'
            return
          end

          engine.run_save_to_sqlite
          puts '✅ Success: Data saved to SQLite successfully'
        else
          puts '⚠️ Skipped: SQLite save not enabled in config'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during SQLite save'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_save_to_mongodb(engine)
      puts 'Test 7: Save to MongoDB'

      begin
        if engine.config['run_save_to_mongodb'] == 1
          engine.connect_to_database

          if engine.database_connector.nil?
            puts '❌ Failed: Database connection not established.'
            return
          end

          engine.run_save_to_mongodb
          puts '✅ Success: Data saved to MongoDB successfully'
        else
          puts '⚠️ Skipped: MongoDB save not enabled in config'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during MongoDB save'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_archive_file(engine)
      puts 'Test: Archive generated files'

      begin
        generated_files_dir = engine.instance_variable_get(:@generated_files_dir)

        unless Dir.exist?(generated_files_dir)
          puts "❌ Failed: Directory #{generated_files_dir} does not exist."
          return
        end

        engine.run_archive_file

        if File.exist?(@archive_name)
          puts "✅ Success: Archive created successfully: #{@archive_name}"

          Zip::File.open(@archive_name) do |zipfile|
            if zipfile.entries.empty?
              puts '❌ Failed: Archive is empty.'
            else
              puts "✅ Success: Archive contains #{zipfile.entries.size} files."
            end
          end
        else
          puts '❌ Failed: Archive not created.'
        end
      rescue StandardError => e
        puts '❌ Failed: Error during archiving'
        puts "   Error: #{e.message}"
      end

      puts "\n"
    end

    def test_archive_sender(engine)
      puts 'Test 9: Archive Sender'

      begin
        Sidekiq::Testing.fake! do
          test_email = 'kripatura1032@gmail.com'
          test_options = { 'subject' => 'Test Archive' }

          ArchiveSender.jobs.clear
          engine.send_archive_via_email(test_email, test_options)

          if ArchiveSender.jobs.size == 1
            job = ArchiveSender.jobs.first
            puts '✅ Success: Archive sending job queued successfully'
            puts "   Queue: #{job['queue']}"
            puts "   Arguments: email=#{job['args'][1]}, subject=#{job['args'][2]['subject']}"

            if job['args'][1] == test_email && job['args'][2]['subject'] == test_options['subject']
              puts '✅ Success: Job arguments are correct'
            else
              puts '❌ Failed: Job arguments are incorrect'
            end
          else
            puts '❌ Failed: Archive sending job was not queued'
          end
        end

        puts "\nTesting actual email sending..."
        Sidekiq::Testing.inline! do
          test_email = 'kripatura1032@gmail.com'
          test_options = { 'subject' => 'Test Archive' }

          engine.send_archive_via_email(test_email, test_options)
          puts '✅ Success: Email sending process completed'
        rescue StandardError => e
          puts '❌ Failed: Error during email sending'
          puts "   Error: #{e.message}"
          puts '   Backtrace:'
          puts e.backtrace[0..2]
        end
      rescue StandardError => e
        puts '❌ Failed: Error during archive sender test'
        puts "   Error: #{e.message}"
        puts '   Backtrace:'
        puts e.backtrace[0..2]
      ensure
        Sidekiq::Testing.disable!
      end

      puts "\n"
    end
  end
end

MyApplication::TestEngine.new.run_tests
