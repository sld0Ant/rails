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
          "time"     => ":time"
        }.freeze

        def entity_attributes
          attributes.map do |attr|
            type = ACTIVE_MODEL_TYPES[attr.type.to_s] || ":string"
            { name: attr.name, type: type }
          end
        end
    end
  end
end
