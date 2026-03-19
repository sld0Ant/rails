# frozen_string_literal: true

require "rails/generators/named_base"

module Rails
  module Generators
    class RepositoryGenerator < NamedBase # :nodoc:
      source_root File.expand_path("templates", __dir__)

      check_class_collision suffix: "Repository"

      def create_repository_file
        template "repository.rb", File.join("app/repositories", class_path, "#{file_name}_repository.rb")
      end

      private

        def file_name
          @_file_name ||= super.sub(/_repository\z/i, "")
        end
    end
  end
end
