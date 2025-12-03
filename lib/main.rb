require_relative 'app_config_loader.rb'
require 'sidekiq/testing'

class Main
  CONFIG_PATH = 'config'
  DEFAULT_CONFIG_PATH = 'config/default_config.yaml'

  def self.run
    config_loader = MyApplication::AppConfigLoader.new
    config_loader.load_libs
    config = config_loader.config(DEFAULT_CONFIG_PATH, CONFIG_PATH)
    config_loader.pretty_print_config_data

    unless config
      puts "Failed to load configuration from #{CONFIG_PATH}"
      return
    end

    operations = config['operations']

    configurator = MyApplication::Configurator.new
    configurator.configure(operations)

    engine = MyApplication::Engine.new(configurator.config)
    engine.run(configurator.config)

    Main.test_archive_sender(engine)
  end

  def self.output_config(config)
    return unless config.nil? || config.empty?
    puts 'Configuration is nil!'
    nil
  end

  def self.test_archive_sender(engine)
    puts 'Test 9: Archive Sender'

    begin
      Sidekiq::Testing.fake! do
        test_email = 'kripatura1032@gmail.com'
        test_options = { 'subject' => 'Archive' }

        MyApplication::ArchiveSender.jobs.clear
        engine.send_archive_via_email(test_email, test_options)

        if MyApplication::ArchiveSender.jobs.size == 1
          job = MyApplication::ArchiveSender.jobs.first
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
        test_options = { 'subject' => 'Archive' }

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

if __FILE__ == $PROGRAM_NAME
  Main.run
end
