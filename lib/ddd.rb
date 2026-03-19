# frozen_string_literal: true

require_relative "ddd/ir"
require_relative "ddd/schema_registry"
require_relative "ddd/emitter"
require_relative "ddd/emitter/openapi"

DDD::Emitter.register(:openapi, DDD::Emitter::OpenAPI)
