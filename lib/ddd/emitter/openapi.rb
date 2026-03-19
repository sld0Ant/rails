# frozen_string_literal: true

require "yaml"
require_relative "base"

module DDD
  module Emitter
    class OpenAPI < Base
      TYPE_MAP = {
        "integer"  => { "type" => "integer", "format" => "int64" },
        "string"   => { "type" => "string" },
        "text"     => { "type" => "string" },
        "float"    => { "type" => "number",  "format" => "float" },
        "decimal"  => { "type" => "number",  "format" => "double" },
        "boolean"  => { "type" => "boolean" },
        "date"     => { "type" => "string",  "format" => "date" },
        "datetime" => { "type" => "string",  "format" => "date-time" },
        "time"     => { "type" => "string",  "format" => "time" }
      }.freeze

      def emit(resources, title: "DDD API", version: "1.0.0", **_opts)
        doc = {
          "openapi" => "3.0.3",
          "info" => { "title" => title, "version" => version },
          "paths" => {},
          "components" => { "schemas" => {} }
        }

        resources.each do |resource|
          add_schemas(doc, resource)
          add_paths(doc, resource)
        end

        YAML.dump(doc)
      end

      private

      def add_schemas(doc, resource)
        name = resource["name"]
        attrs = resource["attributes"]
        permit = resource["permit"]

        full_props = {}
        input_props = {}

        attrs.each do |attr_name, info|
          prop = TYPE_MAP[info["type"]] || { "type" => "string" }
          full_props[attr_name] = prop
          input_props[attr_name] = prop if permit.include?(attr_name)
        end

        doc["components"]["schemas"][name] = {
          "type" => "object",
          "properties" => full_props
        }

        doc["components"]["schemas"]["#{name}Input"] = {
          "type" => "object",
          "properties" => input_props,
          "required" => permit
        }
      end

      def add_paths(doc, resource)
        name = resource["name"]
        plural = resource["plural"]

        collection_path = "/#{plural}"
        member_path = "/#{plural}/{id}"

        doc["paths"][collection_path] = {
          "get" => operation("List all #{plural}", "200", array_ref(name)),
          "post" => operation("Create #{name}", "201", ref(name), input_body(name))
        }

        doc["paths"][member_path] = {
          "get" => operation("Show #{name}", "200", ref(name), nil, id_param),
          "patch" => operation("Update #{name}", "200", ref(name), input_body(name), id_param),
          "delete" => delete_operation("Delete #{name}", id_param)
        }
      end

      def operation(summary, status, response_schema, request_body = nil, parameters = nil)
        op = { "summary" => summary, "responses" => {
          status => { "description" => "Success", "content" => {
            "application/json" => { "schema" => response_schema }
          } }
        } }
        op["requestBody"] = request_body if request_body
        op["parameters"] = [parameters] if parameters
        op
      end

      def delete_operation(summary, parameters)
        {
          "summary" => summary,
          "parameters" => [parameters],
          "responses" => { "204" => { "description" => "No Content" } }
        }
      end

      def ref(name) = { "$ref" => "#/components/schemas/#{name}" }
      def array_ref(name) = { "type" => "array", "items" => ref(name) }
      def input_body(name) = { "required" => true, "content" => {
        "application/json" => { "schema" => { "$ref" => "#/components/schemas/#{name}Input" } }
      } }
      def id_param = { "name" => "id", "in" => "path", "required" => true, "schema" => { "type" => "integer" } }
    end
  end
end
