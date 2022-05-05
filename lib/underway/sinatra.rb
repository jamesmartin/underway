require "underway/sinatra/app_info"

# Repopen Sinatra to add helpers to the app
module Sinatra
  module Underway
    def debug_route(request)
      log(request.inspect)
    end

    def verbose_logging?
      !!::Underway::Settings.configuration.verbose_logging
    end

    def log(message)
      if verbose_logging?
        ::Underway::Settings.configuration.logger.info(message)
      end
    end

    def gh_api(route, **kwargs)
      ::Underway::Api.invoke(route, **kwargs)
    end
  end
end
