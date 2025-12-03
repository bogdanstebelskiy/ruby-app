require 'mechanize'
require 'yaml'
require_relative 'logger_manager'

module MyApplication
  class SimpleWebsiteParser
    attr_reader :config, :agent, :item_collection

    def initialize(config_file_path, item_collection = ItemCollection.new)
      @config = load_config(config_file_path)
      @agent = Mechanize.new
      @item_collection = item_collection

      LoggerManager.initialize_logger(config_file_path)
    end

    def load_config(config_file_path)
      YAML.load_file(config_file_path)
    rescue Errno::ENOENT
      puts "Config file not found: #{config_file_path}"
      {}
    rescue Psych::SyntaxError => e
      puts "Error loading YAML config file: #{e.message}"
      {}
    end

    def start_parse
      return unless check_start_url

      page = agent.get(config['web_scraping']['start_url'])
      product_links = extract_products_links(page)

      threads = []
      product_links.each do |link|
        threads << Thread.new do
          product_url = File.join(config['web_scraping']['start_url'], link['href'])
          parse_product_page(product_url)
        end
      end
      threads.each(&:join)
    end

    def check_start_url
      url = config['web_scraping']['start_url']
      response = agent.head(url)
      if response.code.to_i == 200
        puts 'Start URL is accessible.'
        true
      else
        puts "Start URL is not accessible (HTTP code #{response.code})."
        false
      end
    rescue Mechanize::ResponseCodeError => e
      puts "Error accessing start URL: #{e.message}"
      false
    end

    def extract_products_links(page)
      page.search(config['web_scraping']['product_link_selector'])
    end

    def parse_product_page(url)
      page = agent.get(url)
      product_name = extract_product_name(page)
      product_price = extract_product_price(page)
      product_description = extract_product_description(page)
      product_image = extract_product_image(page)
      product_category = extract_product_category(page)

      image_path = save_product_image(product_image, product_name, product_category)

      item = Item.new(
        name: product_name,
        price: product_price,
        description: product_description,
        image_path: image_path,
        category: product_category
      )

      item_collection.add_item(item)

      LoggerManager.log_processed_file(product_name)
    rescue StandardError => e
      LoggerManager.log_error("Error parsing product page #{url}: #{e.message}")
    end

    def extract_product_name(page)
      page.at(config['web_scraping']['product_name_selector'])&.text&.strip
    end

    def extract_product_price(page)
      page.at(config['web_scraping']['product_price_selector'])&.text&.strip
    end

    def extract_product_description(page)
      page.at(config['web_scraping']['product_description_selector'])&.text&.strip
    end

    def extract_product_image(page)
      page.at(config['web_scraping']['product_image_selector'])&.[]('src')
    end

    def extract_product_category(page)
      page.at(config['web_scraping']['product_category_selector'])&.text&.strip
    end

    def save_product_image(image_url, product_name, category)
      return unless image_url

      category_dir = File.join('media_dir', category || 'default_category')
      Dir.mkdir(category_dir) unless Dir.exist?(category_dir)

      image_name = "#{product_name.gsub(/\s+/, '_').downcase}.jpg"
      image_path = File.join(category_dir, image_name)

      begin
        image = agent.get(image_url)
        File.open(image_path, 'wb') { |f| f.write(image.body) }
        LoggerManager.log_processed_file(image_name)

        image_path
      rescue StandardError => e
        LoggerManager.log_error("Error downloading image for #{product_name}: #{e.message}")
        nil
      end
    end

    def check_url_response(url)
      response = agent.head(url)
      response.code.to_i == 200
    rescue Mechanize::ResponseCodeError => e
      puts "Error accessing URL: #{e.message}"
      false
    end
  end
end
