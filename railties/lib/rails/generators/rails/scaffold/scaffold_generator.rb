# frozen_string_literal: true

require "rails/generators/rails/resource/resource_generator"

module Rails
  module Generators
    class ScaffoldGenerator < ResourceGenerator # :nodoc:
      remove_hook_for :resource_controller
      remove_class_option :actions

      class_option :api, type: :boolean,
        desc: "Generate API-only endpoint"
      class_option :resource_route, type: :boolean
    end
  end
end
