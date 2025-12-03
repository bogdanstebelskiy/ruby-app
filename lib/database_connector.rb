require 'yaml'
require 'sqlite3'
require 'mongo'
require_relative 'logger_manager'

module MyApplication
  class DatabaseConnector
    attr_reader :db

    def initialize(config_file_path)
      LoggerManager.initialize_logger(config_file_path)
      @logger = LoggerManager.logger
      @db = nil
      @logger.info("DatabaseConnector initialized with config file: #{config_file_path}")
      @config = load_config(config_file_path)
    end

    def connect_to_database
      case @config['database_type']
      when 'sqlite'
        connect_to_sqlite
      when 'mongodb'
        connect_to_mongodb
      else
        error_message = "Unsupported database type: #{@config['database_type']}"
        @logger.error(error_message)
        raise UnsupportedDatabaseTypeError, error_message
      end
    rescue UnsupportedDatabaseTypeError => e
      @logger.error("Error: #{e.message}")
    end

    def close_connection
      if @db
        if @db.is_a?(SQLite3::Database)
          @db.close
          @logger.info('SQLite database connection closed.')
        elsif @db.is_a?(Mongo::Client)
          @db.close
          @logger.info('MongoDB database connection closed.')
        end
        @db = nil
      else
        @logger.warn('No active database connection to close.')
      end
    end

    def save_to_sqlite(items)
      if @db.nil?
        @logger.error('Failed to connect to the database, @db is nil.')
        return
      end

      begin
        create_items_table
        @logger.info("Starting to save #{items.size} items to SQLite...")

        @db.transaction
        items.each do |item|
          @logger.info("Inserting item: #{item.name}, #{item.price}, #{item.description}, #{item.category}, #{item.image_path}")
          @db.execute(
            'INSERT INTO items (name, price, description, category, image_path) VALUES (?, ?, ?, ?, ?)',
            [item.name, item.price, item.description, item.category, item.image_path]
          )
        end
        @db.commit
        @logger.info('Data saved to SQLite database successfully.')
      rescue SQLite3::Exception => e
        @db.rollback
        @logger.error("Failed to save data to SQLite: #{e.message}")
      end
    end

    def save_to_mongodb(items)
      if @db.nil?
        @logger.error('Failed to connect to the database, @db is nil.')
        return
      end

      begin
        collection = @db[:items]
        if collection.count_documents == 0
          @logger.info("Collection 'items' does not exist. MongoDB will create it automatically when we insert data.")
        end

        @logger.info("Starting to save #{items.size} items to MongoDB...")
        bulk_items = items.map do |item|
          {
            name: item.name,
            price: item.price,
            description: item.description,
            category: item.category,
            image_path: item.image_path,
          }
        end

        collection.insert_many(bulk_items)
        @logger.info('Data saved to MongoDB successfully.')
      rescue Mongo::Error => e
        @logger.error("Failed to save data to MongoDB: #{e.message}")
      end
    end

    private

    def load_config(config_file_path)
      YAML.load_file(config_file_path)['database_config']
    rescue Errno::ENOENT
      @logger.error("Config file not found: #{config_file_path}")
      {}
    rescue Psych::SyntaxError => e
      @logger.error("Error loading YAML config file: #{e.message}")
      {}
    end

    def connect_to_sqlite
      db_file = @config['sqlite_database']['db_file']
      timeout = @config['sqlite_database']['timeout'] || 5000
      pool_size = @config['sqlite_database']['pool_size'] || 5

      begin
        @db = SQLite3::Database.new(db_file, { timeout:, cache_size: pool_size })
        @logger.info("Connected to SQLite database at #{db_file}.")
      rescue SQLite3::Exception => e
        @logger.error("Failed to connect to SQLite: #{e.message}")
        @db = nil
      end
    end

    def connect_to_mongodb
      uri = @config['mongodb_database']['uri']
      db_name = @config['mongodb_database']['db_name']

      begin
        client = Mongo::Client.new(uri)
        @db = client.use(db_name)

        @logger.info("Connected to MongoDB database '#{db_name}' at #{uri}.")
        collection_names = @db.database.collection_names
        @logger.info("Collections in database '#{db_name}': #{collection_names.join(', ')}")
      rescue Mongo::Error => e
        @logger.error("Failed to connect to MongoDB: #{e.message}")
        @db = nil
      end
    end

    def create_items_table
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          description TEXT,
          category TEXT,
          image_path TEXT
        );
      SQL
      @logger.info('Ensured "items" table exists in SQLite database.')
    end
  end

  class UnsupportedDatabaseTypeError < StandardError; end
end
