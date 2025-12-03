require 'zip'
require 'fileutils'

module MyApplication
  class FileArchiver
    def self.archive_files(files, archive_name = 'output_archive.zip')
      return if files.empty?

      temp_dir = 'temp_files'
      FileUtils.mkdir_p(temp_dir)

      files.each do |file|
        if File.exist?(file)
          FileUtils.cp(file, temp_dir)
        else
          puts "❌ Failed: File #{file} does not exist."
          return
        end
      end

      begin
        Zip::File.open(archive_name, Zip::File::CREATE) do |zipfile|
          Dir["#{temp_dir}/**/*"].each do |file|
            zipfile.add(file.sub("#{temp_dir}/", ''), file)
            puts "✅ Added #{file} to archive."
          end
        end
        puts "✅ Archive created successfully: #{archive_name}"
      rescue StandardError => e
        puts "❌ Failed to create archive: #{e.message}"
      ensure
        FileUtils.rm_rf(temp_dir)
      end
    end
  end
end
