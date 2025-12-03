require_relative '../lib/item.rb'
require_relative '../lib/logger_manager'

module MyApplication
  def self.run_tests
    puts "Тест 1: Створення об'єкта Item з параметрами"
    item1 = Item.new(name: "Товар 1", price: 150)
    puts item1.to_s
    puts "--------------------"

    puts "Тест 2: Створення об'єкта Item з параметрами за замовчуванням"
    item2 = Item.new
    puts item2.info
    puts "--------------------"

    puts "Тест 3: Використання блоку для налаштування атрибутів"
    item3 = Item.new(name: "Товар 3", price: 200) do |i|
      i.description = "Опис товару 3"
      i.category = "Категорія 3"
    end
    puts item3.info
    puts "--------------------"

    puts "Тест 4: Перетворення в хеш"
    puts item3.to_h
    puts "--------------------"

    puts "Тест 5: Порівняння об'єктів Item"
    item4 = Item.new(name: "Товар 4", price: 100)
    item5 = Item.new(name: "Товар 5", price: 250)

    puts "item4 > item5: #{item4 > item5}"
    puts "item4 < item5: #{item4 < item5}"
    puts "item4 == item5: #{item4 == item5}"
    puts "--------------------"

    puts "Тест 6: Генерація фіктивного товару"
    fake_item = Item.generate_fake
    puts "Фіктивний товар:"
    puts fake_item.info
    puts "--------------------"

    puts "Тест 7: Логування"
    LoggerManager.log_processed_file("Тест завершено")
  end
end

MyApplication.run_tests
