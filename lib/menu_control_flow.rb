# A class to control the flow of the menu system. It tracks the state of the
# menu as the user interacts with it, queueing and removing operations as the
# user moves through each menu screen. For example, if the user indicates they
# want to delete a kit, it adds into the operations queue each step required to
# make that happen and moves through them.
# The operation stack was implemented to enable easier integrations testing, as
# well as decouple the methods from one another, allowing for easier addition 
# or manipulation of menu actions in the future.
# Requires a class that wraps the API and returns parsed JSON representing the
# objects from the Typekit API.
# Also requires an IO class, which returns to it the information that it needs
# to complete its desired operation. The IO interface should return the 
# information in the format required to be passed to the API wrapper.
class MenuControlFlow
  def initialize(api_wrapper, io_class)
    @api = api_wrapper
    @io = io_class
    @operation_stack = [:test_authentication, :main_menu, :quit]
    @prev_operation_result = nil
  end

  # run takes an operation off the stack and calls the method for that 
  # operation with the result of the previous operation, if appropriate
  def run
    @io.welcome
    until (operation = @operation_stack.shift) == :quit
      # get args for send; don't send @prev_operation_result if it's nil
      send_opts = [operation, @prev_operation_result].compact
      @prev_operation_result = self.send *send_opts
    end
    @io.goodbye
  end

  # test authentication and return nil
  def test_authentication
    @api.test_authentication
    return
  end

  # displays the main menu, add the selected next op to the stack, return nil
  def main_menu
    main_menu_options = {'Interact with Existing Kits' => :list_and_select_kit,
                         'Create a new Kit' => :prompt_kit_params, 
                         'Quit' => :quit}
    
    op = @io.select_from_options("What would you like to do?", main_menu_options)
    @operation_stack.unshift op
    
    # return nil, because there's nothing to pass onto the next method
    return
  end

  # list all Kits associated with the account, prompt user to choose one
  def list_and_select_kit
    resp = @api.list_kits

    kit_ids = resp['kits'].map { |h| h['id'] }

    if kit_ids.empty?
      choice = @io.yes?("No Kits found! Would you like to create one?")
      @operation_stack.unshift(choice ? :prompt_kit_params : :quit)
      return
    end

    # fetch information about each kit to get their names for user selection
    # note: If there are a lot of kits, this is definitely slow. This could
    # overcome in a couple ways that I could think of: with multithreading to 
    # make multiple requests at once, or with an async implementation to make 
    # multiple requests at once, but since my account can only have a single 
    # Kit at a time I wasn't able to implement or test a solution.
    kits = {}
    kit_ids.each do |id|
      resp = @api.kit_info(id)
      unless resp['error'].nil?
        @io.print_error resp['error']
        @operation_stack.unshift :quit
        return
      end
      kit_info = resp['kit']
      # map each Kit's name to its ID, for menu selection
      kits[kit_info["name"]] = kit_info['id']
    end

    kit_id = @io.select_from_options("Select a Kit:", kits)

    @operation_stack.unshift :select_kit_action

    # now that the next action is on the stack, return the ID to act on
    kit_id
  end

  # select an action to perform on a kit
  # can take in an id to pass back to act on
  def select_kit_action(kit_id=nil)
    actions = { 'View Kit info' => :view_kit,
                'Update Kit' => :prompt_kit_params, 
                'Delete Kit' => :delete_kit }
    
    action = @io.select_from_options("What would you like to do with this Kit?", 
                                     actions)

    # if the selected action is to view the kit info, add the :after_view operation
    @operation_stack.unshift :after_view if action == :view_kit
    @operation_stack.unshift action

    kit_id
  end

  # meant to be run after Kit info is displayed to the console to ask if the 
  # user wants to update the Kit they've just been shown
  def after_view(kit_id)
    choice = @io.yes?("Don't like what you see? Do you want to edit this kit?")
    @operation_stack.unshift :prompt_kit_params if choice
    kit_id
  end

  def prompt_kit_params(kit_id=nil)
    # if we're creating a new kit (id is nil) then we don't have an id to 
    # continue working on in after_view, so don't add it
    @operation_stack.unshift :after_view unless kit_id.nil?
    @operation_stack.unshift :save_kit
    params = {'id' => kit_id}
    # return a hash of the kit params, along with the kit_id
    params.merge(@io.prompt_kit_params)
  end

  # get the Kit with the passed ID and ask IO to display its information
  def view_kit(id)
    resp = @api.kit_info(id)
    @io.display_kit_info resp
    # return the id so a queued operation can continue operating on this kit
    id
  end

  # save a Kit, either creating a new one or updating an existing one
  # expects a list of valid parameters to pass to the API wrapper and an 'id'
  # field if this is an update operation 
  def save_kit(params)
    # separate the ID from the other params
    id = params['id']
    params.reject! { |k,v| k == 'id' }

    resp = @api.save_kit(params, id)
    @io.display_kit_info resp
    # return the id so a queued operation can continue operating on this kit
    id
  end

  # delete the Kit with the specified ID
  def delete_kit(id)
    resp = @api.delete_kit(id)
    @io.display_kit_deleted resp
  end

end