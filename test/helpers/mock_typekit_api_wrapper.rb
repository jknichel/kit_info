require './lib/typekit_api_wrapper'

# A mock class of the TypekitApiWrapper. In it, all methods will be written to
# hardcoded data that matches the output of the class when it makes a legitamate
# API request. This is being faked here because there is no way to get 
# consistent data back from the API for testing without making calls to a real, 
# closely controlled account.
class MockTypekitApiWrapper < TypekitApiWrapper
  # if @mock_error is false, fake success responses will be returned
  # if @mock_error is true, fake error responses will be returned
  attr_accessor :mock_not_found_error, :mock_bad_request_error, 
                :mock_authentication_error, :empty_kit_list

  # fake responses to return for testing
  FAKE_KIT_LIST = {"kits"=>[{"id"=>"abc1def", 
                   "link"=>"/api/v1/json/kits/abc1def"}]}
  FAKE_KIT_INFO_RESPONSE = {"kit"=>{"id"=>"abc1def", "name"=>"Example", 
    "analytics"=>false, "domains"=>["example.com"], "families"=>[], 
    "optimize_performance"=>false}}
  FAKE_KIT_DELETED_RESPONSE = {"ok"=>"true"}

  # fake versions of the most common error responses for testing
  FAKE_NOT_FOUND_RESPONSE = {"error"=>"404 Not Found"}
  FAKE_BAD_REQUEST_RESPONSE = {"error"=>"400 Bad request"}
  FAKE_AUTHENTICATION_ERROR = {"error"=>"401 not authorized"}

  # set @mock_error to false to send the fake success responses initially
  def initialize
    @mock_authentication_error = false
    @mock_not_found_error = false
    @mock_bad_request_error = false
    @empty_kit_list = false
  end

  # override each of the methods used in InteractiveMenu, and have them return
  # either a matching fake success or error response

  # the actual version of this method will only fail due to an authentication 
  # error, assuming a valid internet connection
  def list_kits
    raise RestClient::Unauthorized if @mock_authentication_error
    @empty_kit_list ? {'kits' => []} : FAKE_KIT_LIST
  end
  alias_method :test_authentication, :list_kits
  
  # authentication errors will have already been caught before this is called,
  # so return a 404 not found as it's the most likely
  def kit_info(id)
    @mock_not_found_error ? FAKE_NOT_FOUND_RESPONSE : FAKE_KIT_INFO_RESPONSE
  end

  # bad parameters in the request are the most likely issue here
  def save_kit(payload, id=nil)
    resp = FAKE_KIT_INFO_RESPONSE
    @mock_bad_request_error ? FAKE_BAD_REQUEST_RESPONSE : resp.merge(payload)
  end

  # again, a 404 not found is the most common error response here
  def delete_kit(id)
    @mock_not_found_error ? FAKE_NOT_FOUND_RESPONSE : FAKE_KIT_DELETED_RESPONSE
  end
end
