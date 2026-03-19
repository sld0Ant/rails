## ADDED Requirements

### Requirement: Emitter registration and dispatch
`DDD::Emitter` SHALL provide `.register(format, klass)` and `.emit(format, resources, **options)` class methods.

#### Scenario: Register and emit
- **WHEN** `DDD::Emitter.register(:openapi, DDD::Emitter::OpenAPI)` is called
- **THEN** `DDD::Emitter.emit(:openapi, resources)` SHALL call `DDD::Emitter::OpenAPI.new.emit(resources)` and return the result string

#### Scenario: Unknown format raises error
- **WHEN** `DDD::Emitter.emit(:unknown, resources)` is called
- **THEN** it SHALL raise `DDD::Emitter::UnknownFormatError` with a message listing available formats

#### Scenario: List registered formats
- **WHEN** multiple emitters are registered
- **THEN** `DDD::Emitter.formats` SHALL return array of registered format symbols

### Requirement: Emitter base class contract
Each emitter SHALL inherit `DDD::Emitter::Base` and implement `#emit(resources)` returning a String.

#### Scenario: Unimplemented emit raises
- **WHEN** a subclass does not override `#emit`
- **THEN** calling `#emit` SHALL raise `NotImplementedError`

### Requirement: Custom emitter registration
Users SHALL be able to register custom emitters in app initializers.

#### Scenario: Custom format in initializer
- **WHEN** `DDD::Emitter.register(:graphql, MyApp::GraphQLEmitter)` is called in `config/initializers/ddd.rb`
- **THEN** `rake ddd:emit[graphql]` SHALL use that emitter
