require 'tty-prompt'

# A class for handling IO with for Typekit API command line applications. It 
# wraps a few methods from tty-prompt to expose them to other classes that use
# this class. However, it also has a few methods that prompt the user for input
# related to Typekit API request payloads, formats that input to send to the
# API, and returns that formatted input.
class TypekitMenuIO
  # initialize the class with a tty-prompt object for user interaction
  def initialize
    @console = TTY::Prompt.new
  end

  # a few methods to wrap tty-prompt methods; see their documentation for info
  def say(text)
    @console.say(text)
  end

  def error(text)
    @console.error(text)
  end

  def select_from_options(prompt, options_hash)
    @console.select(prompt, options_hash)
  end

  # wraps the tty-prompt yes? but handles unexpected input instead of raising
  def yes?(prompt)
    begin
      @console.yes?(prompt)
    rescue TTY::Prompt::ConversionError => exception
      say "Invalid input. Proceeding as if \"Y\" was entered."
      return true
    end
  end

  def welcome
    say "Welcome to kit_info!"
  end

  def goodbye
    say "Thanks for using kit_info!"    
  end

  # ask the user for the parameters necessary to update or create a kit
  # returns a hash of the parameters, in the form:
  # { name: String, domains: Array, families[0][id]: String } 
  # plus the output of the prompt_family_ids method
  def prompt_kit_params
    say("Please enter the specified parameter values.")
    say("Leave any field you don't wish to specify/update blank.")

    params = @console.collect do
      key(:name).ask("Name:")
      key(:domains).ask("Domains (comma separated list):") do |list|
        list.convert -> (input) { input.split(/,\s*/) }
      end
    end
    params.merge(prompt_family_ids)
  end

  # ask for the number of font families to add, and the ID for each
  # returns an empty hash if no families are to be entered, otherwise returns
  # a hash of the IDs in the format that the API requests.
  def prompt_family_ids
    begin
      count = @console.ask("Number of Font Families to add (enter 0 to skip):", 
                            convert: :int)
    rescue TTY::Prompt::ConversionError=> exception
      # if input is something other than a number, skip the input
      say "Invalid input, skipping Font Family input."
      return {}
    end
    count ||= 0
    family_ids = {}
    count.times do |i|
      # ask for each Family ID and format their key as the API desires:
      # "families[index][id]"="id"
      id = @console.ask("Enter ID for Family ##{i + 1}:")
      family_ids["families[#{i}][id]"] = id
    end
    family_ids
  end

  # pretty print the passed JSON to the console, unless there's an error
  def print_json(json)
    say JSON.pretty_generate(json) 
  end

  # display a kit_info response, or an error if the response contains one
  def display_kit_info(kit_info_response)
    if kit_info_response['error'].nil?
      print_json kit_info_response 
    else
      print_error kit_info_response['error']
    end
  end

  # inform user the kit was deleted, or show error if the response contains one
  def display_kit_deleted(kit_deleted_response)
    if kit_deleted_response['error'].nil?
      @console.ok "Kit successfully deleted!"
    else
      print_error kit_deleted_response['error']
    end
  end

  # method to explain to the user the types of errors that will come back from
  # the API during the running of the application
  def print_error(error_message)
    error "An error occurred!"
    if error_message.include? "400"
      # 400 error indicates a bad request. At this point, it's most likely that
      # the user has passed an invalid Font Family ID. However, the API also 
      # returns a 400 error in the case that a new Kit is attempting to be
      # created when the user is at their maximim Kit capacity.
      say "The API indicated that the request was bad."
      say "It's likely because the entered Font Family ID was invalid,"
      say "or that you've reached your maximum Kit limit."
    elsif error_message.include? "404"
      # 404 error indicates that a resource wasn't found. This is likely 
      # because of an invalid ID. This shouldn't show up, as the menu shouldn't
      # let the user make a request on an ID that doesn't exist, but it's still
      # a common error code so include some message for it.
      say "The API indicated that it couldn't find the resource."
      say "Make sure that the the Kit wasn't deleted while using this application."
    end
  end
end
