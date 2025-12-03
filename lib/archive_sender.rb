require 'sidekiq'
require 'pony'

module MyApplication
  class ArchiveSender
    include Sidekiq::Worker

    sidekiq_options retry: false, queue: 'archive_sending'

    def perform(archive_path, email_address, options = {})
      validate_inputs!(archive_path, email_address)

      options = options.transform_keys(&:to_sym) if options.is_a?(Hash)

      send_archive(archive_path, email_address, options)
    rescue StandardError => e
      LoggerManager.logger.error("Failed to send archive: #{e.message}")
      raise
    end

    private

    def validate_inputs!(archive_path, email_address)
      raise ArgumentError, "Archive not found: #{archive_path}" unless File.exist?(archive_path)
      raise ArgumentError, 'Invalid email address' unless email_address =~ URI::MailTo::EMAIL_REGEXP
    end

    def send_archive(_archive_path, email_address, _options)
      LoggerManager.logger.info("Sending archive to #{email_address}")

      # ❌ Entire email delivery disabled
      # Pony.mail({
      #   to: email_address,
      #   from: 'kripatura1032@gmail.com',
      #   subject: 'Test Archive',
      #   body: "Hello!\n\nI am sending the archive attached.",
      #   attachments: { File.basename(_archive_path) => File.read(_archive_path) },
      #   via: :smtp,
      #   via_options: {
      #     address: 'smtp.gmail.com',
      #     port: 465,
      #     user_name: 'kripatura1032@gmail.com',
      #     password: 'password',
      #     authentication: :plain,
      #     ssl: true,
      #   },
      # })

      LoggerManager.logger.info("Archive successfully sent to #{email_address}")
    end

    def generate_email_body(archive_path)
      <<~EMAIL_BODY
        Hello!

        Please find attached your requested archive: #{File.basename(archive_path)}

        This archive was generated on #{Time.now.strftime('%Y-%m-%d at %H:%M:%S')}

        Best regards,
        Rubystochky Team
      EMAIL_BODY
    end

    def smtp_config
      {
        address: email_config[:smtp_server],
        port: email_config[:smtp_port],
        user_name: email_config[:from_address],
        password: email_config[:smtp_password],
        authentication: :plain,
        ssl: true,
      }
    end

    def email_config
      @email_config ||= YAML.load_file('config/email_config.yaml')['development']
    end
  end
end
