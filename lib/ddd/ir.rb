# frozen_string_literal: true

require "json"

module DDD
  module IR
    VERSION = "1.0"

    READONLY_ATTRIBUTES = %w[id created_at updated_at].freeze

    RUBY_TYPES = %w[
      integer string float decimal boolean
      date datetime time text
    ].freeze

    def self.to_json(resources)
      JSON.pretty_generate(
        "$schema" => "ddd-ir/#{VERSION}",
        "resources" => resources.map { |r| normalize_resource(r) }
      )
    end

    def self.from_json(json_string)
      data = JSON.parse(json_string)
      validate!(data)
      data["resources"]
    end

    def self.validate!(data)
      unless data.is_a?(Hash) && data["$schema"]&.start_with?("ddd-ir/")
        raise InvalidIRError, "Missing or invalid $schema — expected 'ddd-ir/#{VERSION}'"
      end

      unless data["resources"].is_a?(Array)
        raise InvalidIRError, "Missing 'resources' array"
      end

      data["resources"].each_with_index do |resource, i|
        %w[name plural attributes permit operations].each do |key|
          unless resource.key?(key)
            raise InvalidIRError, "Resource ##{i} (#{resource['name'] || 'unnamed'}) missing '#{key}'"
          end
        end
      end
    end

    def self.normalize_resource(resource)
      resource.transform_keys(&:to_s)
    end

    class InvalidIRError < StandardError; end
  end
end
