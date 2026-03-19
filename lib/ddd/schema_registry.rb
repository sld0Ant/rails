# frozen_string_literal: true

require_relative "ir"

module DDD
  class SchemaRegistry
    READONLY = IR::READONLY_ATTRIBUTES

    def self.collect(root: Rails.root)
      new(root).collect
    end

    def initialize(root)
      @root = root
    end

    def collect
      endpoint_files.map { |path| build_resource(path) }.compact
    end

    private

    def endpoint_files
      Dir.glob(@root.join("app/endpoints/*_endpoint.rb"))
        .reject { |f| File.basename(f) == "application_endpoint.rb" }
    end

    def build_resource(path)
      class_name = File.basename(path, ".rb").camelize
      endpoint_class = Object.const_get(class_name)

      entity_name = endpoint_class.resource_name.to_s.camelize
      entity_class = Object.const_get(entity_name)
      record_class = Object.const_get("#{entity_name}Record")
      plural = endpoint_class.resource_name.to_s.pluralize

      {
        "name" => entity_name,
        "plural" => plural,
        "path" => "/#{plural}",
        "attributes" => build_attributes(entity_class),
        "permit" => endpoint_class.permitted_params.map(&:to_s),
        "operations" => build_operations(plural),
        "validators" => build_validators(entity_class)
      }
    rescue NameError => e
      warn "SchemaRegistry: skipping #{path} — #{e.message}"
      nil
    end

    def build_attributes(entity_class)
      entity_class.attribute_types.each_with_object({}) do |(name, type), hash|
        hash[name] = {
          "type" => type.type.to_s,
          "nullable" => !%w[id].include?(name),
          "readonly" => READONLY.include?(name)
        }
      end
    end

    def build_operations(plural)
      [
        { "action" => "index",   "method" => "GET",    "path" => "/#{plural}" },
        { "action" => "show",    "method" => "GET",    "path" => "/#{plural}/{id}" },
        { "action" => "create",  "method" => "POST",   "path" => "/#{plural}" },
        { "action" => "update",  "method" => "PATCH",  "path" => "/#{plural}/{id}" },
        { "action" => "destroy", "method" => "DELETE",  "path" => "/#{plural}/{id}" }
      ]
    end

    def build_validators(entity_class)
      entity_class.validators.map do |validator|
        {
          "type" => validator.class.name.demodulize.underscore.sub("_validator", ""),
          "fields" => validator.attributes.map(&:to_s)
        }
      end
    end
  end
end
