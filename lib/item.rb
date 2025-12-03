require 'faker'

module MyApplication
  class Item
    include Comparable

    attr_accessor :name, :price, :description, :category, :image_path

    def initialize(params = {})
      @name = params.fetch(:name, 'Unnamed Item')
      @price = params.fetch(:price, 0.0)
      @description = params.fetch(:description, 'No description available')
      @category = params.fetch(:category, 'General')
      @image_path = params.fetch(:image_path, 'default_image.png')

      LoggerManager.initialize_logger('config/logging.yaml')
      LoggerManager.log_processed_file(@name)

      yield(self) if block_given?
    end

    def to_s
      instance_variables.map do |var|
        "#{var.to_s.delete('@')}: #{instance_variable_get(var)}"
      end.join(', ')
    rescue StandardError => e
      LoggerManager.log("Error in info method: #{e.message}")
      'Error displaying item information'
    end

    alias info to_s

    def to_h
      instance_variables.each_with_object({}) do |var, hash|
        hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
      end
    end

    def inspect
      "#<#{self.class}: #{self}>"
    end

    def update
      yield(self) if block_given?
    end

    def self.generate_fake
      Item.new(
        name: Faker::Commerce.product_name,
        price: Faker::Commerce.price,
        description: Faker::Lorem.sentence,
        category: Faker::Commerce.department(max: 1),
        image_path: Faker::LoremFlickr.image
      )
    end

    def <=>(other)
      return nil unless other.is_a?(Item)

      @price <=> other.price
    end
  end
end
