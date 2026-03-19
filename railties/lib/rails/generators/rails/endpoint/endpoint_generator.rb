# frozen_string_literal: true

require "rails/generators/named_base"

module Rails
  module Generators
    class EndpointGenerator < NamedBase # :nodoc:
      source_root File.expand_path("templates", __dir__)

      argument :attributes, type: :array, default: [], banner: "field[:type] field[:type]"

      check_class_collision suffix: "Endpoint"

      def create_endpoint_file
        template "endpoint.rb", File.join("app/endpoints", class_path, "#{file_name}_endpoint.rb")
      end

      private

        def file_name
          @_file_name ||= super.sub(/_endpoint\z/i, "")
        end

        def singular_resource_name
          file_name.singularize
        end

        def permitted_fields
          attributes.map { |a| a.reference? ? ":#{a.name}_id" : ":#{a.name}" }.join(", ")
        end

        def sortable_fields
          ([":created_at"] + attributes.reject(&:reference?).map { |a| ":#{a.name}" }).join(", ")
        end

        def filterable_fields
          attributes.select(&:reference?).map { |a| ":#{a.name}_id" }.join(", ")
        end
    end
  end
end
