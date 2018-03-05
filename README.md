# Underway

[![Build Status](https://travis-ci.org/jamesmartin/underway.svg?branch=master)](https://travis-ci.org/jamesmartin/underway)

Underway is a Ruby gem that helps developers quickly prototype [GitHub
Apps](https://developer.github.com/apps/).

Underway consists of some convenience wrappers for the GitHub REST API, with a
particular focus on generating credentials for accessing installation resources
associated with a GitHub App. Access tokens are cached using Sqlite3 for
convenience.

If you like rapid prototyping with [Sinatra](http://sinatrarb.com) you can use
the included Sinatra routes, which allow you to quickly get access to a JWT or
access token for your App and its installations. Starting with a Sinatra
application is a fast way to build a GitHub App prototype and explore how
GitHub Apps work with the GitHub REST API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "underway", "~> 1.0"
```

And then run:

```
bundle
```

Or install it globally with:

```
gem install underway
```

## Configuration

First, follow the documentation to [create a GitHub
App](https://developer.github.com/apps/building-github-apps/creating-a-github-app/).

When you're done creating a new App you should have:

- Your GitHub App's ID (an integer)
- A private key file (.pem)
- A webhook secret (optional)

Make a copy of the
[config.json.example](https://github.com/jamesmartin/underway/blob/master/config.json.example)
file in a location readable by your application and edit the file to match your
GitHub App's settings.

At its core, Underway is just a Ruby library and can be used in virtually any
application.  To get started quickly and test out your new GitHub App you might
want to use the included [Sinatra](http://sinatrarb.com) routes. A complete
[example Sinatra
application](https://github.com/jamesmartin/underway/blob/master/example/app.rb)
is included with Underway and shows how to configure the gem and include the
informational routes.


If you would prefer to configure Underway manually, or are not building a
Sinatra application, do something like this:

```ruby
require "underway"

# This assumes that your configuration file and private key file is located in
# the same directory as the current ruby file.

Underway::Settings.configure do |config|
  config.app_root = __FILE__
  config.config_filename = "config.json"
end
```
