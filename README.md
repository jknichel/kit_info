# Welcome to kit_info!

This small command line application, written in Ruby, provides an interface for
interacting with the Kits in your Typekit account.

## Features

* Interactive command line menu 
* View Kit information
* Create a new Kit
* Update Kit infomration
* Delete a Kit

## Setup and Installation

Make sure that Ruby and Bundler are installed on your machine.
In the base directory of the project run:

```bash
bundle install
```

You may also need to make the kit_info file in `bin/` executable by running the
following in the base directory of the project:

```bash
chmod u+x bin/kit_info
```

## Contents
* [1. Usage](#1-usage)
* [2. Errors](#2-errors)
  * [2.1 Authorization Failed!](#21-authorization-failed)
  * [2.2 Unexpected response](#22-unexpected-response)
  * [2.3 Resource not found](#23-resource-not-found)
  * [2.4 Bad request](#24-bad-request)
* [3. Testing](#3-testing)

Finally, you'll have to add your Typekit API key to allow kit_info to access
your Typekit account. Open `lib/util/typekit_auth_key.rb` with your favorite 
text editor and replace `"YOUR_KEY_HERE"` with your API key, in quotes.

## 1. Usage

In order to start up kit_info, just run:

```bash
bin/kit_info
```

You'll be greeted with a welcome message and the main menu.

```
Welcome to kit_info!
What would you like to do? (Use arrow keys, press Enter to select)
‣ Interact with Existing Kits
  Create a new Kit
  Quit

```

The application will run you through the rest from there! It was designed to be
simple and intuitive.

## 2. Errors

You may see some error messages while running kit_info. This section of the 
README aims to explain them in a little more detail in case you encounter one.

### 2.1 Authorization Failed

This is indicative of the API key defined in `lib/util/typekit_auth_key` being 
incorrect. Double check that they key is entered properly.

### 2.2 Unexpected response

The API returned information in response to a request that is missing the 
expected data. This is unlikely to be an issue with kit_info. This error 
should be very uncommon and is indicative of something changing within the 
Typekit API.

### 2.3 Resource not found

The API couldn't find the object matching the ID that was requested. kit_info 
should only be sending valid IDs, based on the results of previous responses 
from the API. This may happen if a Kit is deleted through another interface 
while kit_info is running.

### 2.4 Bad request

The API returned a response saying that the request contained bad data. This 
happens if the User entered invalid data (such as a non-existent Font Family 
ID) while trying to update or create a kit. 

There is one peculiarity with the Typekit API that would also cause this error 
to be received. If the account contains its maximum number of Kits, and it a 
create kit request is received, the API will return a bad request error. This 
is another reason this error could show up.

## 3. Testing

A rake task for testing makes running the test suite easy! Simply enter:

~~~
rake test
~~~
