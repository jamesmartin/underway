# frozen_string_literal: true
require "json"

begin
  require "openssl"
  Underway::Settings.config.open_ssl_available = true
rescue LoadError
  Underway::Settings.config.open_ssl_available = false
end

module Sinatra
  module Underway
    module EventServer
      OpenSSLUnavailableError = Class.new(RuntimeError)

      class Event
        def self.from_request(request)
          event = request.env["HTTP_X_GITHUB_EVENT"]
          new(event, parsed_hook_payload(request))
        end

        def self.parsed_hook_payload(request)
          return request.params unless request.params.empty? # Rack has parsed the response

          request.body.rewind
          JSON.parse(request.body.read)
        end

        def self.body_reader(*args)
          args.each do |attr|
            class_eval <<-EOM, __FILE__, __LINE__
              def #{attr}
                body["#{attr}"]
              end
            EOM
          end
        end

        body_reader :repository, :issue, :sender, :installation

        attr_reader :event, :action, :body

        def initialize(event, params)
          @event, @action = event, params["action"]
          @body = params
        end
      end

      class EventRegistry
        attr_reader :registry

        DEFAULT_PROC = Proc.new { "Ok we're underway!" }
        WILDCARD = "*"

        def initialize
          @registry = {}
        end

        def register(event, block)
          event, action = event.split(".")
          action ||= WILDCARD

          registry[event] ||= {}
          registry[event][action] = block
        end

        def for(event)
          registered_for_type = registry[event.event]
          return DEFAULT_PROC unless registered_for_type

          registered_for_action = registered_for_type[event.action]
          return registered_for_action if registered_for_action

          registered_for_type[WILDCARD] || DEFAULT_PROC
        end
      end

      def self.included(parent)
        parent.register(EventServer) if parent.respond_to?(:register)
      end

      def self.registered(app)
        if defined?(Rack::PostBodyContentTypeParser)
          unless app.middleware.find {|arr| arr.include?(Rack::PostBodyContentTypeParser)}
            app.use Rack::PostBodyContentTypeParser
          end
        end

        app.set(:event_registrations, EventRegistry.new)

        app.post ::Underway::Settings.config.webhook_endpoint do
          halt(401) unless EventServer.webhook_authorized?(request)

          event = Event.from_request(request)

          settings.event_registrations.for(event).call(event)
        end
      end

      def on(event, &block)
        settings.event_registrations.register(event, block)
      end

      def webhook_authorized?(request)
        raise OpenSSLUnavailableError unless ::Underway::Settings.config.open_ssl_available?

        github_signature = request.env["HTTP_X_HUB_SIGNATURE"]
        return true unless github_signature
        return false if ::Underway::Settings.config.webhook_secret.nil?

        signature = "sha1=" + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'),
                                ::Underway::Settings.config.webhook_secret,
                                request.body.read)
        Rack::Utils.secure_compare(signature, github_signature)
      end
      module_function :webhook_authorized?
    end
  end

  register(Underway::EventServer)
end
