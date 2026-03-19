# frozen_string_literal: true

require "rails/generators/resource_helpers"
require "rails/generators/rails/model/model_generator"

module Rails
  module Generators
    class ResourceGenerator < ModelGenerator # :nodoc:
      include ResourceHelpers

      hook_for :resource_controller, required: true do |controller|
        invoke controller, [ controller_name, options[:actions] ]
      end

      class_option :actions, type: :array, banner: "ACTION ACTION", default: [],
                             desc: "Actions for the resource controller"

      hook_for :resource_route, required: true

      hook_for :entity, type: :boolean, default: true do |entity|
        invoke entity, [ name, *attributes.map(&:to_s) ]
      end

      hook_for :repository, type: :boolean, default: true do |repository|
        invoke repository, [ name ]
      end

      hook_for :service, type: :boolean, default: true do |service|
        invoke service, [ name ]
      end

      hook_for :endpoint, type: :boolean, default: true do |endpoint|
        invoke endpoint, [ name.pluralize, *attributes.map(&:to_s) ]
      end

      class << self
        def desc(description = nil)
          ERB.new(File.read(usage_path)).result(binding)
        end
      end
    end
  end
end
