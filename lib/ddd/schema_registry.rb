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
        "validators" => build_validators(entity_class),
        "relations" => build_relations(record_class, entity_name),
        "collection" => build_collection(endpoint_class),
        "links" => build_links(plural, build_relations(record_class, entity_name)),
        "states" => build_states(entity_class),
        "aggregate_root" => (entity_class.aggregate_root if entity_class.respond_to?(:aggregate_root) && entity_class.aggregate_root),
        "aggregate" => (entity_class.aggregate_parent if entity_class.respond_to?(:aggregate_parent) && entity_class.aggregate_parent),
        "authorization" => build_authorization(endpoint_class)
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

    def build_authorization(endpoint_class)
      return {} unless endpoint_class.respond_to?(:authorize_config) && endpoint_class.authorize_config.any?

      endpoint_class.authorize_config.transform_keys(&:to_s).transform_values { |v| v.map(&:to_s) }
    end

    def build_states(entity_class)
      return {} unless entity_class.respond_to?(:transitions_config) && entity_class.transitions_config.any?

      {
        "field" => entity_class.state_field,
        "transitions" => entity_class.transitions_config.transform_values { |v|
          { "from" => v[:from].to_s, "to" => v[:to].to_s }
        }.transform_keys(&:to_s)
      }
    end

    def build_links(plural, relations)
      links = { "self" => "/#{plural}/{id}" }

      relations.each do |name, info|
        case info["kind"]
        when "belongs_to"
          related_plural = info["resource"].downcase.pluralize
          links[name] = "/#{related_plural}/{#{name}_id}"
        when "has_many"
          links[name] = "/#{plural}/{id}/#{name}"
        end
      end

      links
    end

    def build_collection(endpoint_class)
      coll = {}
      coll["sort"] = endpoint_class.sortable_fields if endpoint_class.respond_to?(:sortable_fields) && endpoint_class.sortable_fields.any?
      coll["filter"] = endpoint_class.filterable_fields if endpoint_class.respond_to?(:filterable_fields) && endpoint_class.filterable_fields.any?
      coll["search"] = endpoint_class.searchable_fields if endpoint_class.respond_to?(:searchable_fields) && endpoint_class.searchable_fields.any?
      coll["per_page"] = endpoint_class.default_per_page if endpoint_class.respond_to?(:default_per_page) && endpoint_class.default_per_page
      coll
    end

    def build_relations(record_class, entity_name)
      relations = {}

      record_class.reflect_on_all_associations.each do |assoc|
        target_name = assoc.class_name.delete_suffix("Record")

        case assoc.macro
        when :belongs_to
          relations[assoc.name.to_s] = {
            "kind" => "belongs_to",
            "resource" => target_name,
            "required" => assoc.options[:optional] != true
          }
        when :has_many
          if assoc.options[:through]
            relations[assoc.name.to_s] = {
              "kind" => "has_many",
              "resource" => target_name,
              "through" => assoc.options[:through].to_s.camelize.singularize
            }
          else
            relations[assoc.name.to_s] = {
              "kind" => "has_many",
              "resource" => target_name
            }
          end
        end
      end

      relations
    end
  end
end
