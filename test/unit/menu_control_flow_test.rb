require 'minitest/autorun'
require 'tty-prompt'

require_relative '../helpers/menu_control_flow_test_class'
require_relative '../helpers/mock_typekit_menu_io'
require_relative '../helpers/mock_typekit_api_wrapper'

class MenuControlFlowTest < Minitest::Test
  include MockTypekitIO

  FAKE_ID = "abc1def"
  FAKE_PARAMS = {"name" => "Example", "domains" => ["example.com"]}

  def setup
    @io = TypekitMenuIOFakeOutput.new
    @wrapper = MockTypekitApiWrapper.new
    @control = MenuControlFlowTestClass.new(@wrapper, @io)
  end

  def test_main_menu
    # set the mock output
    @io.output = :list_and_select_kit
    assert_nil @control.main_menu
    assert_equal :list_and_select_kit, @control.operation_stack.first

    # reset and check the second option
    setup
    @io.output = :prompt_kit_params
    assert_nil @control.main_menu
    assert_equal :prompt_kit_params, @control.operation_stack.first
  end

  def test_list_and_select_kit
    # first run through with an a kit list that isn't empty and an ID
    @io.output = FAKE_ID
    assert_equal FAKE_ID, @control.list_and_select_kit
    assert_equal :select_kit_action, @control.operation_stack.first

    # reset and run with empty kit list and IO returning true to simulate
    # selecting the "create a kit" option
    setup
    @wrapper.empty_kit_list = true
    @io.output = true
    assert_nil @control.list_and_select_kit
    assert_equal :prompt_kit_params, @control.operation_stack.first

    # reset and run with empty kit list and IO returning false to simulate
    # selecting the quit option
    setup
    @wrapper.empty_kit_list = true
    @io.output = false
    assert_nil @control.list_and_select_kit
    assert_equal :quit, @control.operation_stack.first
  end

  def test_select_kit_action
    # make sure that the return from IO is on the stack, and that when an ID
    # isn't passed the return value is nil
    @io.output = :view_kit
    assert_nil @control.select_kit_action
    assert_equal :view_kit, @control.operation_stack.first

    # reset and test with ID passed
    setup
    @io.output = :delete_kit
    assert_equal FAKE_ID, @control.select_kit_action(FAKE_ID)
    assert_equal :delete_kit, @control.operation_stack.first
  end

  def test_prompt_kit_params
    # test that the fake params come back fine (without passed ID)
    @io.output = FAKE_PARAMS
    assert_equal FAKE_PARAMS.merge({'id' => nil}), @control.prompt_kit_params
    assert_equal :save_kit, @control.operation_stack.first

    # reset and test that fake params come back fine (with passed ID)
    setup
    @io.output = FAKE_PARAMS
    assert_equal FAKE_PARAMS.merge({'id' => FAKE_ID}), 
                 @control.prompt_kit_params(FAKE_ID)
    assert_equal :save_kit, @control.operation_stack.first
  end
end
