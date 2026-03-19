# frozen_string_literal: true

require_relative "emitter/base"

module DDD
  module Emitter
    class UnknownFormatError < StandardError; end

    @registry = {}

    class << self
      def register(format, klass)
        @registry[format.to_sym] = klass
      end

      def emit(format, resources, **options)
        klass = @registry[format.to_sym]
        unless klass
          available = @registry.keys.join(", ")
          raise UnknownFormatError, "Unknown format '#{format}'. Available: #{available}"
        end
        klass.new.emit(resources, **options)
      end

      def formats
        @registry.keys
      end
    end
  end
end
