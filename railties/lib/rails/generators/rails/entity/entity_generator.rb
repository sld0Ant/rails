# frozen_string_literal: true

require "rails/generators/named_base"

module Rails
  module Generators
    class EntityGenerator < NamedBase # :nodoc:
      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "field[:type] field[:type]"

      check_class_collision

      def create_entity_file
        template "entity.rb", File.join("app/entities", class_path, "#{file_name}.rb")
      end

      def create_test_file
        template "entity_test.rb", File.join("test/entities", class_path, "#{file_name}_test.rb")
      end

      private

        ACTIVE_MODEL_TYPES = {
          "string"   => ":string",
          "text"     => ":string",
          "integer"  => ":integer",
          "float"    => ":float",
          "decimal"  => ":decimal",
          "boolean"  => ":boolean",
          "date"     => ":date",
          "datetime" => ":datetime",
          "time"     => ":time",
          "json"     => ":string"
        }.freeze

        def entity_attributes
          regular = attributes.reject(&:reference?).map do |attr|
            type = ACTIVE_MODEL_TYPES[attr.type.to_s] || ":string"
            { name: attr.name, type: type }
          end

          fk = attributes.select(&:reference?).map do |attr|
            { name: "#{attr.name}_id", type: ":integer" }
          end

          fk + regular
        end
    end
  end
end
