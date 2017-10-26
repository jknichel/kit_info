require './lib/typekit_menu_io' 

# This module holds two classes, both written to allow for simulated input for
# testing.
module MockTypekitIO
  # constants to hold more complex keystrokes for use in integration testing
  RETURN = "\r"
  UP_ARROW = "\e[A"
  DOWN_ARROW = "\e[B"

  # Mock testing class. It implements the same methods as TypekitMenuIO, but takes in 
  # TTY's TestPrompt object to allow for tests to simulate user input.
  class TypekitMenuIOTestPrompt < TypekitMenuIO
    def initialize(test_prompt)
      @console = test_prompt
    end
  end

  # Another mock testing class which allows a test to specify the return values
  # for all methods in the class.
  class TypekitMenuIOFakeOutput < TypekitMenuIO
    attr_accessor :output
    def initialize
      TypekitMenuIO.instance_methods(false).each do |method|
        self.class.send(:define_method, method) { |*args| return @output }
      end
    end
  end
end
