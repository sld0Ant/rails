# frozen_string_literal: true

require "rails/generators/named_base"

module Rails
  module Generators
    class ServiceGenerator < NamedBase # :nodoc:
      source_root File.expand_path("templates", __dir__)

      check_class_collision suffix: "Service"

      def create_service_file
        template "service.rb", File.join("app/services", class_path, "#{file_name}_service.rb")
      end

      private

        def file_name
          @_file_name ||= super.sub(/_service\z/i, "")
        end
    end
  end
end
