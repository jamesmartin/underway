require "underway/sinatra/app_info"

# Repopen Sinatra to add helpers to the app
module Sinatra
  module Underway
    def debug_route(request)
      log(request.inspect)
    end

    def verbose_logging?
      !!::Underway::Settings.config.verbose_logging
    end

    def log(message)
      if verbose_logging?
        ::Underway::Settings.config.logger.info(message)
      end
    end

    def gh_api(*args)
      ::Underway::Api.invoke(*args)
    end
  end
end
