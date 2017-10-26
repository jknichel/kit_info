require 'minitest/autorun'
require 'tty-prompt'

require_relative '../helpers/menu_control_flow_test_class'
require_relative '../helpers/mock_typekit_menu_io'
require_relative '../helpers/mock_typekit_api_wrapper'

class UserFlowTest < Minitest::Test
  include MockTypekitIO

  NOT_FOUND_ERROR_MESSAGE = "The API indicated that it couldn't find the resource."
  BAD_REQUEST_ERROR_MESSAGE = "The API indicated that the request was bad."

  def setup
    @prompt = TTY::TestPrompt.new
    @io = TypekitMenuIOTestPrompt.new(@prompt)
    @wrapper = MockTypekitApiWrapper.new
    @control = MenuControlFlowTestClass.new(@wrapper, @io)
  end

  def test_authentication_error
    @wrapper.mock_authentication_error = true
    assert_raises(RestClient::Unauthorized) { @control.run }
  end
  
  # Each of these integration tests follows the same basic flow:
  # 1. setup the input to mimic user input
  # 2. run the menu with that input
  # 3. check that the operations_log matches the expected actions in order
  def test_view_kit_info_flow
    navigate_through_view_kit
    @control.run
    expected_operations = [:test_authentication, :main_menu, 
                           :list_and_select_kit, :select_kit_action, :view_kit,
                           :after_view, :quit]
    assert_equal expected_operations, @control.operations_log
  end

  def test_update_kit_flow
    navigate_through_update_kit
    @control.run
    expected_operations = [:test_authentication, :main_menu, 
                           :list_and_select_kit, :select_kit_action, 
                           :prompt_kit_params, :save_kit, :after_view, :quit]
    assert_equal expected_operations, @control.operations_log
  end

  def test_delete_kit_flow
    navigate_through_delete_kit
    @control.run
    expected_operations = [:test_authentication, :main_menu, 
                           :list_and_select_kit, :select_kit_action, 
                           :delete_kit, :quit]
    assert_equal expected_operations, @control.operations_log
  end

  def test_create_kit_flow
    navigate_through_create_kit
    @control.run
    expected_operations = [:test_authentication, :main_menu, 
                           :prompt_kit_params, :save_kit, :quit]
    assert_equal expected_operations, @control.operations_log
  end

  # these last tests will run through the menus while telling the mock API 
  # wrapper to send error responses
  def test_view_kit_info_error_flow
    # tell the mock wrapper to return not found errors on view kit requests
    @wrapper.mock_not_found_error = true
    navigate_through_view_kit
    @control.run
    assert_includes @prompt.output.string, NOT_FOUND_ERROR_MESSAGE
  end

  def test_update_kit_error_flow
    # tell the mock wrapper to return bad request errors on update and create 
    # kit requests
    @wrapper.mock_bad_request_error = true
    navigate_through_update_kit
    @control.run
    assert_includes @prompt.output.string, BAD_REQUEST_ERROR_MESSAGE
  end

  def test_delete_kit_error_flow
    @wrapper.mock_not_found_error = true
    navigate_through_delete_kit
    @control.run
    assert_includes @prompt.output.string, NOT_FOUND_ERROR_MESSAGE
  end

  def test_create_kit_error_flow
    @wrapper.mock_bad_request_error = true
    navigate_through_create_kit
    @control.run
    assert_includes @prompt.output.string, BAD_REQUEST_ERROR_MESSAGE
  end

  # methods for navigating through the menus down a certain path
  def navigate_through_view_kit
    # select "Interact with Existing Kits", select the first option "Example",
    # select "View Kit info", answer "n" to "Do you want to edit this kit"
    @prompt.input << RETURN << RETURN << RETURN << "n#{RETURN}"
    @prompt.input.rewind
  end

  def navigate_through_update_kit
    # select "Interact with Existing kits", select the first option "Example",
    # select "Update Kit", enter a name, enter domains, indicate 0 families,
    # answer "n" to "Do you want to edit this kit"
    @prompt.input << RETURN << RETURN << DOWN_ARROW << RETURN 
    @prompt.input << "Update#{RETURN}" << "example.com#{RETURN}" << RETURN
    @prompt.input << "n#{RETURN}"
    @prompt.input.rewind
  end

  def navigate_through_create_kit
    # select "Create a new Kit", enter "Example" for Name, enter "example.com"
    # for Domains, return without input to skip family entering, end
    @prompt.input << DOWN_ARROW << RETURN << "Example#{RETURN}" 
    @prompt.input << "example.com#{RETURN}" << RETURN
    @prompt.input.rewind
  end

  def navigate_through_delete_kit
    # select "Interact with Existing kits", select the first option "Example",
    # select "Delete Kit", end
    @prompt.input << RETURN << RETURN << DOWN_ARROW << DOWN_ARROW << RETURN
    @prompt.input.rewind
  end
end
