require 'json'
require 'rest-client'

# This class simply wraps the Typekit API. It provides methods that take in 
# the required fields to construct a valid API request, send the request, and
# then return the response.
class TypekitApiWrapper
  API_URL_BASE = 'https://typekit.com/api/v1/json/'
  AUTH_KEY_HEADER = 'X-Typekit-Token'

  def initialize(key)
    @request_header = {AUTH_KEY_HEADER => key}
  end

  # First, a method for making requests with RestClient. It requires the 
  # specification of a method (GET, POST, DELETE), the endpoint to access,
  # and an optional payload for POST requests.
  def make_request(method, endpoint, payload={})
    params = ["#{API_URL_BASE}/#{endpoint}", payload, @request_header]
    begin
      JSON.parse RestClient.send(method.to_sym, *params.reject { |p| p.empty? })
    rescue RestClient::Unauthorized => e
      # an authorization error is indicative that the configuration won't work,
      # not that an individual request errored, so raise instead of recovering
      raise e
    rescue RestClient::Exception => e
      # attempt to handle other RestClient exceptions gracefully
      # return the erorr message and keep moving
      return { "error" => e.message }
    end
  end

  # The below methods make requests to the Typekit API endpoints and return
  # hashes from the parsed JSON responses. The methods that make POST requests
  # take in payloads in the form of parsed JSON.
  def list_kits
    resp = make_request :get, "kits"
    check_response_for_field resp, "kits"
  end
  # alias this method as test_authentication, as it has the simplest request
  # and the authentication error will be caught and raised by make_request
  alias_method :test_authentication, :list_kits

  # request information for the Kit with the specified ID
  def kit_info(id)
    resp = make_request :get, "kits/#{id}"
    check_response_for_field resp, "kit"
  end

  # if an ID is passed it will update the Kit with that ID with the passed
  # payload, otherwise it will create a new kit based on the passed payload
  def save_kit(payload, id=nil)
    url = "kits" + (id.nil? ? "" : "/#{id}")
    resp = make_request :post, url, payload
    check_response_for_field resp, "kit"
  end

  # delete the Kit with the specified ID
  def delete_kit(id)
    resp = make_request :delete, "kits/#{id}"
    check_response_for_field resp, "ok"
  end

  # Check if the expected field is present. If it is, return the response.
  # If the field isn't present, and it isn't an error response, then raise
  # an exception.
  def check_response_for_field(resp, field_name)
    if resp[field_name].nil? && resp['error'].nil?
      raise MissingExpectedFieldError
    end
    resp
  end
end

# An error to be used in case the response from the endpoint is missing 
# expected data.
class MissingExpectedFieldError < StandardError
  def initialize(msg="The response from the endpoint is missing an expected value!")
    super(msg)
  end
end
