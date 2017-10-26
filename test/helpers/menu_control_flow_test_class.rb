require './lib/menu_control_flow'

# A copy of the MenuControlFlow, but provides an accessor method to allow for 
# testing the state of the control flow based on the contents of the 
# @operation_stack and @prev_operation_result. 
# It also keeps track of a list of all operations that are run in order they 
# are run for integration testing.
class MenuControlFlowTestClass < MenuControlFlow
  attr_reader :operation_stack, :prev_operation_result, :operations_log

  def initialize(api_wrapper, io_class)
    @operations_log = []
    super(api_wrapper, io_class)
  end

  # copy of run with one key difference: each operation is saved to
  # @operations_log for integration testing
  def run
    @io.welcome
    until (operation = @operation_stack.shift) == :quit
      @operations_log.push operation
      send_opts = [operation, @prev_operation_result].compact
      @prev_operation_result = self.send *send_opts
    end
    @operations_log.push :quit
    @io.goodbye
  end
end
