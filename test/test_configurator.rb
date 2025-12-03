require 'stringio'

class ConfiguratorTest
  def initialize
    @configurator = Configurator.new
  end

  def test_initialize
    expected_config = {
      run_website_parser: 0,
      run_save_to_csv: 0,
      run_save_to_json: 0,
      run_save_to_yaml: 0,
      run_save_to_sqlite: 0
    }
    if @configurator.config == expected_config
      puts 'Test initialize: PASSED'
    else
      puts 'Test initialize: FAILED'
    end
  end

  def test_configure_valid_keys
    @configurator.configure(run_website_parser: 1, run_save_to_csv: 1)
    if @configurator.config[:run_website_parser] == 1 && @configurator.config[:run_save_to_csv] == 1
      puts 'Test configure (valid keys): PASSED'
    else
      puts 'Test configure (valid keys): FAILED'
    end
  end

  def test_configure_invalid_key
    original_stdout = $stdout
    $stdout = StringIO.new
    @configurator.configure(unknown_param: 1)
    output = $stdout.string
    $stdout = original_stdout

    if output.include?('Попередження: Невідомий параметр конфігурації - unknown_param')
      puts 'Test configure (invalid key warning): PASSED'
    else
      puts 'Test configure (invalid key warning): FAILED'
    end
  end

  def test_available_methods
    expected_methods = %i[
      run_website_parser
      run_save_to_csv
      run_save_to_json
      run_save_to_yaml
      run_save_to_sqlite
    ]
    if Configurator.available_methods == expected_methods
      puts 'Test available_methods: PASSED'
    else
      puts 'Test available_methods: FAILED'
    end
  end

  def run_all_tests
    test_initialize
    test_configure_valid_keys
    test_configure_invalid_key
    test_available_methods
  end
end

test_runner = ConfiguratorTest.new
test_runner.run_all_tests
