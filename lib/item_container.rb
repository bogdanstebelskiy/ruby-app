module MyApplication
  module ItemContainer
    def self.included(class_instance)
      class_instance.extend(ClassMethods)
      class_instance.include(InstanceMethods)
    end

    module ClassMethods
      def class_info
        "Class: #{name}, Version: 1.0"
      end

      def object_count
        @object_count ||= 0
      end

      def increment_object_count
        @object_count = object_count + 1
      end
    end

    module InstanceMethods
      def add_item(item)
        @items << item
      end

      def remove_item(item)
        @items.delete(item)
      end

      def delete_items
        @items.clear
      end

      def method_missing(method_name, *args, &block)
        if method_name == :show_all_items
          puts 'Items in collection:'
          @items.each { |item| puts item }
        else
          super
        end
      end

      def initialize
        self.class.increment_object_count
        super
      end
    end
  end
end
