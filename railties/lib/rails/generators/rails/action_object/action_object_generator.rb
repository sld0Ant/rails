# frozen_string_literal: true

require "rails/generators/named_base"

module Rails
  module Generators
    class ActionObjectGenerator < NamedBase # :nodoc:
      source_root File.expand_path("templates", __dir__)

      check_class_collision

      def create_action_file
        template "action_object.rb", File.join("app/actions", class_path, "#{file_name}.rb")
      end
    end
  end
end
