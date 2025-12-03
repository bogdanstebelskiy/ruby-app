require 'yaml'
require 'erb'
require 'json'
require 'fileutils'

module MyApplication
  class AppConfigLoader
    attr_reader :config_data

    def initialize
      @config_data = {}
      @loaded_libs = []
    end

    def config(main_config_file, config_dir)
      load_default_config(main_config_file)
      load_config(config_dir)              
      yield(@config_data) if block_given?  
      @config_data                         
    end

    def pretty_print_config_data
      puts JSON.pretty_generate(@config_data)
    end

    def load_default_config(config_file)
      raise "Config file not found: #{config_file}" unless File.exist?(config_file)

      file_content = ERB.new(File.read(config_file)).result
      @config_data = YAML.safe_load(file_content, permitted_classes: [Symbol], aliases: true) || {}
      puts "Loaded main config file: #{config_file}"
    end

    def load_config(config_dir)
      raise "Config directory not found: #{config_dir}" unless Dir.exist?(config_dir)

      Dir.glob(File.join(config_dir, '*.yaml')).each do |file|
        file_content = ERB.new(File.read(file)).result
        additional_config = YAML.safe_load(file_content, permitted_classes: [Symbol], aliases: true) || {}

        @config_data.merge!(additional_config)
        puts "Loaded additional config file: #{file}"
      end
    end

    def load_libs(libs_dir = 'lib')
      system_libraries = %w[date json yaml fileutils]

      system_libraries.each do |lib|
        next if loaded_lib?(lib)

        require lib
        @loaded_libs << lib
        puts "Loaded system library: #{lib}"
      end

      Dir.glob(File.join(libs_dir, '*.rb')).each do |file|
        next if File.expand_path(file) == __FILE__

        lib_name = File.basename(file, '.rb')
        next if loaded_lib?(lib_name)

        require File.expand_path(file)
        @loaded_libs << lib_name
        puts "Loaded local library: #{lib_name}"
      end
    end

    def loaded_lib?(lib_name)
      @loaded_libs.include?(lib_name)
    end
  end
end
