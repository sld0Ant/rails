## ADDED Requirements

### Requirement: DDD directory structure
`rails new` SHALL generate `app/endpoints/`, `app/actions/`, `app/entities/`, `app/services/`, `app/repositories/`, `app/records/` directories with corresponding base classes.

#### Scenario: New app directories
- **WHEN** `rails new myapp` is run
- **THEN** the generated app SHALL contain directories: `app/endpoints/`, `app/actions/`, `app/entities/`, `app/services/`, `app/repositories/`, `app/records/`
- **THEN** it SHALL NOT contain `app/models/`, `app/controllers/`, `app/views/`, `app/helpers/`

#### Scenario: Base class files
- **WHEN** `rails new myapp` is run
- **THEN** it SHALL create `application_endpoint.rb`, `application_action.rb`, `application_entity.rb`, `application_service.rb`, `application_repository.rb`, `application_record.rb` in their respective directories

### Requirement: Engine autoload paths
`Rails::Engine::Configuration` SHALL register `app/endpoints`, `app/actions`, `app/entities`, `app/services`, `app/repositories`, `app/records` as eager-load paths and SHALL NOT register `app/models`.

#### Scenario: Autoloading DDD directories
- **WHEN** a Rails app boots
- **THEN** classes in `app/entities/`, `app/endpoints/`, `app/actions/`, `app/services/`, `app/repositories/`, `app/records/` SHALL be autoloaded
