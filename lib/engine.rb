require_relative 'item_collection'
require_relative 'logger_manager'
require_relative 'database_connector'
require 'yaml'
require 'zip'

module MyApplication
  class Engine
    attr_reader :config, :logger, :database_connector, :item_collection

    def initialize(config_or_path)
      case config_or_path
      when String
        @config_file_path = config_or_path
        @config = load_config(@config_file_path)
      when Hash
        @config = config_or_path
        @config_file_path = nil
      else
        raise ArgumentError, "Expected String or Hash, got #{config_or_path.class}"
      end
      @logger = nil
      @database_connector = nil
      @item_collection = ItemCollection.new
      @generated_files_dir = 'output'
      @archive_name = 'output_archive.zip'
    end

    def load_config(config_file_path)
      file_content = File.read(config_file_path)
      YAML.safe_load(file_content)
    rescue Errno::ENOENT
      puts "Config file not found: #{config_file_path}"
      {}
    rescue Psych::SyntaxError => e
      puts "Error loading YAML config file: #{e.message}"
      {}
    end

    def initialize_logger
      return if @logger

      LoggerManager.initialize_logger('config/logging.yaml')
      @logger = LoggerManager.logger
      if @logger
        @logger.info('Logger initialized via LoggerManager.')
      else
        puts 'Failed to initialize logger'
      end
    end

    def run(_config_params = nil)
      initialize_logger
      connect_to_database
      params_to_use = @config
      if params_to_use.is_a?(Hash)
        run_methods(params_to_use)
      else
        @logger&.info("Invalid configuration format: expected Hash, got #{params_to_use.class}")
      end
      disconnect_from_database
    rescue StandardError => e
      @logger&.info("Error in run process: #{e.message}")
    end

    def run_methods(config_params)
      puts 'Config params received:'
      puts config_params.inspect
      config_params.each do |method_name, flag|
        puts "Checking method: #{method_name} with flag: #{flag}"
        next unless flag == 1

        method_name_str = method_name.to_s
        if respond_to?(method_name_str, true)
          begin
            puts "Executing method: #{method_name_str}"
            send(method_name_str)
          rescue StandardError => e
            @logger&.info("Error executing method #{method_name_str}: #{e.message}")
            puts "Error: #{e.message}"
          end
        else
          puts "Method #{method_name_str} not found"
          @logger&.info("Method #{method_name_str} not found")
        end
      end
    end

    def connect_to_database
      @database_connector = DatabaseConnector.new('config/database_config.yaml')
      @database_connector.connect_to_database
    rescue StandardError => e
      logger&.error("Error connecting to the database: #{e.message}")
    end

    def disconnect_from_database
      if @database_connector
        @database_connector.close_connection
        logger&.info('Database connection closed.')
      else
        logger&.warn('No database connection to close.')
      end
    end

    def run_website_parser
      logger.info('Running website parser...')
      if @config[:run_website_parser] == 1
        parser = SimpleWebsiteParser.new('config/web_parser.yaml', item_collection)
        parser.start_parse
        logger.info('Website parsing completed successfully.')
      else
        logger.info('Website parsing skipped due to configuration.')
      end
      run_save_to_csv if @config[:run_save_to_csv] == 1
      run_save_to_json if @config[:run_save_to_json] == 1
      run_save_to_yaml if @config[:run_save_to_yaml] == 1
      run_save_to_sqlite if @config[:run_save_to_sqlite] == 1
      run_save_to_mongodb if @config[:run_save_to_mongodb] == 1
    rescue StandardError => e
      logger.error("Error running website parser: #{e.message}")
    end

    def run_save_to_csv
      return unless @logger

      @logger.info('Saving data to CSV...')
      item_collection.save_to_csv
    rescue StandardError => e
      LoggerManager.log_error("Error saving to CSV: #{e.message}")
    end

    def run_save_to_json
      return unless @logger

      @logger.info('Saving data to JSON...')
      item_collection.save_to_json('items.json')
    rescue StandardError => e
      LoggerManager.log_error("Error saving to JSON: #{e.message}")
    end

    def run_save_to_yaml
      return unless @logger

      @logger.info('Saving data to YAML...')
      item_collection.save_to_yml
    rescue StandardError => e
      LoggerManager.log_error("Error saving to YAML: #{e.message}")
    end

    def run_save_to_sqlite
      return unless @logger

      if database_connector.nil?
        @logger.error('Database connector is not initialized.')
      else
        @logger.info('Database connector is initialized.')
      end
      @logger.info('Saving data to SQLite database...')
      database_connector.save_to_sqlite(item_collection.items)
    rescue StandardError => e
      LoggerManager.log_error("Error saving to SQLite: #{e.message}")
    end

    def run_save_to_mongodb
      return unless @logger

      @logger.info('Saving data to MongoDB...')
      database_connector.save_to_mongodb(item_collection.items)
    rescue StandardError => e
      LoggerManager.log_error("Error saving to MongoDB: #{e.message}")
    end

    def run_archive_file
      validate_directory_and_files!
      create_archive(@generated_files_dir, @archive_name)
      logger&.info("Archive created successfully: #{@archive_name}")
    rescue StandardError => e
      logger&.error("Error during archiving: #{e.message}")
      raise
    end

    def validate_directory_and_files!
      unless Dir.exist?(@generated_files_dir)
        raise "Directory #{@generated_files_dir} does not exist."
      end

      if Dir.glob(File.join(@generated_files_dir, '*')).empty?
        raise "No files found in #{@generated_files_dir} to archive."
      end
    end

    def create_archive(directory, archive_name)
      Zip::File.open(archive_name, Zip::File::CREATE) do |zipfile|
        Dir.glob(File.join(directory, '*')).each do |file|
          zipfile.add(File.basename(file), file)
          logger&.info("Added #{file} to archive.")
        end
      end
    end

    def send_archive_via_email(email_address, options = {})
      ensure_archive_exists

      options = options.transform_keys(&:to_s)

      ArchiveSender.perform_async(File.absolute_path(@archive_name), email_address, options)

      logger&.info("Archive sending job successfully queued to #{email_address}")
    rescue StandardError => e
      logger&.error("Failed to queue archive sending: #{e.message}")
      raise
    end

    private

    def ensure_archive_exists
      return if File.exist?(@archive_name)

      logger&.info("Archive not found, creating new one.")
      run_archive_file
    end
  end
end
