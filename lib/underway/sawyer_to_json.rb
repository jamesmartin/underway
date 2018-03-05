require "json"
require "sawyer"

module Underway
  class SawyerToJson
    def self.convert(object)
      JSON.generate(unwrap(object))
    end

    def self.unwrap(object)
      case object
      when Array then object.map { |o| unwrap(o) }
      when Sawyer::Resource then object.to_hash
      else object
      end
    end
  end
end
