require 'minitest/autorun'

require_relative '../helpers/mock_typekit_api_wrapper'
require_relative '../helpers/mock_typekit_menu_io'

# Most classes in MenuIO are just wrappers for tty-prompt methods. Those 
# wrapper methods are not going to be unit tested, because tty-prompts 
# unit testing on those methods should be sufficient.
class TypekitMenuIOTest < Minitest::Test
  include MockTypekitIO

  def setup
    @prompt = TTY::TestPrompt.new
    @io = TypekitMenuIOTestPrompt.new(@prompt)
  end

  # test that user input is returned by prompt_kit_params in the expected format
  def test_prompt_kit_params
    # case: user enters name and domains
    clear_and_add_input("Example\r", "example.com, anotherexample.com\r", "0\r")
    params = @io.prompt_kit_params
    assert_equal 2, params.count
    assert_equal 'Example', params[:name]
    assert_equal ['example.com', 'anotherexample.com'], params[:domains]

    # case: user enters name but no domain
    clear_and_add_input("Example\r", "\r", "0\r")
    params = @io.prompt_kit_params
    assert_equal 2, params.count
    assert_equal 'Example', params[:name]
    assert_nil params[:domains]

    # case: user enters domains but no name
    clear_and_add_input("\r", "example.com, anotherexample.com\r", "0\r")
    params = @io.prompt_kit_params
    assert_equal 2, params.count
    assert_nil params[:name]
    assert_equal ['example.com', 'anotherexample.com'], params[:domains]

    # test that family information is added to the hash successfully
    clear_and_add_input("\r", "\r", "2\r", "abcd\r", "efgh\r")
    params = @io.prompt_kit_params
    assert_equal 4, params.count
    assert_equal "abcd", params['families[0][id]']
    assert_equal "efgh", params['families[1][id]']
  end

  def test_prompt_family_ids
    # case: entering 0 families
    clear_and_add_input("0\r")
    assert_empty @io.prompt_family_ids

    # run for 1-50 family IDs (my limited understanding of the API usecase
    # led me to this number. Not sure what I typical "large" size would be.)
    50.times do |index|
      clear_and_add_input("#{index + 1}\r", *Array.new(index + 1, "abcd\r"))
      families = @io.prompt_family_ids
      assert_equal index + 1, families.count
      # make sure that each family key is present
      index.times { |i| assert_equal "abcd", families["families[#{i}][id]"] }
    end
  end

  def test_display_kit_info
    # shorthand for long constant
    kit_info_resp = MockTypekitApiWrapper::FAKE_KIT_INFO_RESPONSE

    # test that successful Kit info response is printed
    @io.display_kit_info kit_info_resp
    assert_includes @prompt.output.string, JSON.pretty_generate(kit_info_resp)
  end

  def test_display_kit_deleted
    # test that successful delete response is printed
    @io.display_kit_deleted MockTypekitApiWrapper::FAKE_KIT_DELETED_RESPONSE
    assert_includes @prompt.output.string, "Kit successfully deleted!"
  end

  def test_print_error
    # shorthand for long constants
    not_found_resp = MockTypekitApiWrapper::FAKE_NOT_FOUND_RESPONSE
    bad_request_resp = MockTypekitApiWrapper::FAKE_BAD_REQUEST_RESPONSE

    # case: 404 not found error
    @io.print_error not_found_resp['error']
    assert_includes @prompt.output.string, 
                    "The API indicated that it couldn't find the resource."

    # case: 400 bad request
    @io.print_error bad_request_resp['error']
    assert_includes @prompt.output.string,
                    "The API indicated that the request was bad."
  end

  # helper method for clearing the TTY::TestPrompt input and adding all passed
  # strings for the next test
  def clear_and_add_input(*input_strings)
    @prompt.input.rewind
    @prompt.input.truncate(0)
    input_strings.each { |i| @prompt.input << i }
    @prompt.input.rewind
  end
end
