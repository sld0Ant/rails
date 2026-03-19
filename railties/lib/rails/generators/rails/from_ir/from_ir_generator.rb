# frozen_string_literal: true

require "rails/generators/base"
require "json"

module Rails
  module Generators
    class FromIrGenerator < Base # :nodoc:
      source_root File.expand_path("templates", __dir__)

      argument :ir_path, type: :string, banner: "PATH_TO_IR_JSON"

      READONLY_ATTRIBUTES = %w[id created_at updated_at].freeze

      def validate_file
        unless File.exist?(ir_path)
          say_status "error", "File not found: #{ir_path}", :red
          raise SystemExit
        end
      end

      def parse_and_validate
        content = File.read(ir_path)
        @ir_data = JSON.parse(content)

        unless @ir_data.is_a?(Hash) && @ir_data["$schema"]&.start_with?("ddd-ir/")
          say_status "error", "Invalid IR file: missing '$schema' field", :red
          raise SystemExit
        end

        unless @ir_data["resources"].is_a?(Array) && @ir_data["resources"].any?
          say_status "error", "Invalid IR file: missing or empty 'resources' array", :red
          raise SystemExit
        end

        say_status "found", "#{@ir_data['resources'].size} resources in #{ir_path}", :green
      rescue JSON::ParserError => e
        say_status "error", "Invalid JSON: #{e.message}", :red
        raise SystemExit
      end

      def generate_resources
        @ir_data["resources"].each do |resource|
          name = resource["name"]
          attrs = build_attribute_args(resource["attributes"])

          say_status "scaffold", "#{name} #{attrs.join(' ')}", :cyan

          generate "scaffold", name, *attrs,
            "--no-test-framework",
            "--no-resource-route"
        end
      end

      def print_summary
        names = @ir_data["resources"].map { |r| r["name"] }
        say ""
        say "Generated #{names.size} DDD resources: #{names.join(', ')}"
        say ""
        say "Next steps:"
        say "  1. Run migrations:  rails db:migrate"
        say "  2. Add routes to config/routes.rb:"
        @ir_data["resources"].each do |r|
          say "       endpoint #{r['name'].pluralize}Endpoint"
        end
        say "  3. Start server:    rails server"
      end

      private

      def build_attribute_args(attributes)
        attributes.filter_map do |name, info|
          next if READONLY_ATTRIBUTES.include?(name)

          type = info["type"] || "string"
          "#{name}:#{type}"
        end
      end
    end
  end
end
