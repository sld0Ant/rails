# frozen_string_literal: true

module DDD
  module Emitter
    class Base
      def emit(resources)
        raise NotImplementedError, "#{self.class}#emit must return a String"
      end
    end
  end
end
