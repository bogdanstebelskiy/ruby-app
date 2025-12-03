module MyApplication
  require 'logger'
  require 'yaml'

  class LoggerManager
    class << self
      attr_reader :logger

      def initialize_logger(config_file_path)
        config = load_config(config_file_path)

        if config.nil? || config.empty?
          puts "Failed to load configuration from #{config_file_path}."
          return
        end

        log_directory = config[:directory] || 'logs'
        Dir.mkdir(log_directory) unless Dir.exist?(log_directory)

        @logger = Logger.new(File.join(log_directory, config.dig(:files, :application_log) || 'application.log'))
        @logger.level = get_log_level(config[:level] || 'INFO')

        error_logger_path = File.join(log_directory, config.dig(:files, :error_log) || 'error.log')
        @error_logger = Logger.new(error_logger_path)
        @error_logger.level = Logger::ERROR
      end

      def log_processed_file(file_name)
        logger.info("Processed file: #{file_name}")
      end

      def log_error(message)
        @error_logger.error(message)
      end

      private

      def load_config(config_file_path)
        YAML.load_file(config_file_path) || {}
      rescue Errno::ENOENT
        puts "Config file not found: #{config_file_path}"
        {}
      rescue Psych::SyntaxError => e
        puts "Error loading YAML config file: #{e.message}"
        {}
      end

      def get_log_level(level)
        case level.upcase
        when 'DEBUG' then Logger::DEBUG
        when 'INFO' then Logger::INFO
        when 'WARN' then Logger::WARN
        when 'ERROR' then Logger::ERROR
        else Logger::INFO
        end
      end
    end
  end
end
