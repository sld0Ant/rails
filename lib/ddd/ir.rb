# frozen_string_literal: true

require "json"

module DDD
  module IR
    VERSION = "1.2"

    READONLY_ATTRIBUTES = %w[id created_at updated_at].freeze

    RUBY_TYPES = %w[
      integer string float decimal boolean
      date datetime time text references
    ].freeze

    RELATION_KINDS = %w[belongs_to has_many].freeze

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

      resource_names = data["resources"].map { |r| r["name"] }.compact.to_set

      data["resources"].each_with_index do |resource, i|
        %w[name plural attributes permit operations].each do |key|
          unless resource.key?(key)
            raise InvalidIRError, "Resource ##{i} (#{resource['name'] || 'unnamed'}) missing '#{key}'"
          end
        end

        (resource["relations"] || {}).each do |assoc_name, rel|
          target = rel["resource"]
          unless resource_names.include?(target)
            raise InvalidIRError, "Resource '#{resource['name']}' relation '#{assoc_name}' targets '#{target}' which doesn't exist"
          end
        end

        validate_transitions!(resource) if resource["transitions"]
        validate_actions!(resource) if resource["actions"]
      end
    end

    def self.normalize_resource(resource)
      resource.transform_keys(&:to_s)
    end

    def self.topological_sort(resources)
      by_name = resources.each_with_object({}) { |r, h| h[r["name"]] = r }
      visited = {}
      sorted = []

      visit = ->(name) {
        return if visited[name]
        visited[name] = true
        resource = by_name[name]
        return unless resource

        (resource["relations"] || {}).each do |_, rel|
          visit.call(rel["resource"]) if rel["kind"] == "belongs_to"
        end

        sorted << resource
      }

      resources.each { |r| visit.call(r["name"]) }
      sorted
    end

    FORBIDDEN_ACTION_NAMES = %w[index show create update destroy transition custom_action new edit].freeze

    def self.validate_transitions!(resource)
      t = resource["transitions"]
      name = resource["name"]
      raise InvalidIRError, "#{name}: transitions must have 'field'" unless t["field"].is_a?(String)
      raise InvalidIRError, "#{name}: transitions must have 'events'" unless t["events"].is_a?(Hash)

      unless resource["attributes"]&.key?(t["field"])
        raise InvalidIRError, "#{name}: transitions field '#{t['field']}' not in attributes"
      end

      t["events"].each do |event_name, cfg|
        raise InvalidIRError, "#{name}: transition '#{event_name}' must have 'from'" unless cfg.key?("from")
        raise InvalidIRError, "#{name}: transition '#{event_name}' must have 'to'" unless cfg["to"].is_a?(String)
      end
    end

    def self.validate_actions!(resource)
      name = resource["name"]
      transition_names = (resource.dig("transitions", "events") || {}).keys

      resource["actions"].each do |action|
        raise InvalidIRError, "#{name}: action must have 'name'" unless action["name"].is_a?(String)
        raise InvalidIRError, "#{name}: action must have 'method'" unless action["method"].is_a?(String)
        raise InvalidIRError, "#{name}: action must have 'on' (member/collection)" unless %w[member collection].include?(action["on"])

        if FORBIDDEN_ACTION_NAMES.include?(action["name"]) || transition_names.include?(action["name"])
          raise InvalidIRError, "#{name}: action name '#{action['name']}' conflicts with reserved name or transition"
        end
      end
    end

    class InvalidIRError < StandardError; end
  end
end
