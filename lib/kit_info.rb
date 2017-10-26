require_relative 'menu_control_flow'
require_relative 'typekit_menu_io'
require_relative 'typekit_api_wrapper'
require_relative 'util/typekit_auth_key'

class KitInfo
  def self.go
    # initialize the objects for running
    io = TypekitMenuIO.new
    api_wrapper = TypekitApiWrapper.new(TypekitAuthKey::KEY)
    control = MenuControlFlow.new(api_wrapper, io)

    begin
      # calling run on MenuControlFlow starts the application
      control.run
    rescue RestClient::Unauthorized
      # There was an issue with authorization. Warn the user to check their key.
      io.error "Authorization failed!" 
      io.say "Please check your API key defined in lib/typekit_auth_key.rb"
      exit
    rescue MissingExpectedFieldError
      # The API returned a response missing an expected field based on the 
      # requested endpoint. This is unlikely an issue on this end, so warn the
      # user. 
      io.error "The API returned an unexpected response."
      io.error "There may be something wrong with the API. Try again later."
    end
  end
end
