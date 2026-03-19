## ADDED Requirements

### Requirement: ApplicationRepository base class
The framework SHALL provide `ApplicationRepository` with `class_attribute :record_class` and `class_attribute :entity_class`. It SHALL implement `all`, `find`, `create`, `update`, `destroy` methods that operate through AR Records and return Domain Entities.

#### Scenario: Repository find
- **WHEN** `repository.find(id)` is called with an existing record id
- **THEN** it SHALL return a domain Entity populated with the record's attributes

#### Scenario: Repository create with valid data
- **WHEN** `repository.create(attributes)` is called with valid attributes
- **THEN** it SHALL validate via Entity, persist via Record, and return a persisted Entity with id

#### Scenario: Repository create with invalid entity
- **WHEN** `repository.create(attributes)` is called with attributes that fail Entity validation
- **THEN** it SHALL return an Entity with populated errors and SHALL NOT persist to database

#### Scenario: Repository create with DB constraint violation
- **WHEN** `repository.create(attributes)` passes Entity validation but violates a DB constraint
- **THEN** it SHALL catch `ActiveRecord::RecordInvalid`, map record errors to entity.errors, and return the Entity

#### Scenario: Repository update
- **WHEN** `repository.update(id, attributes)` is called with valid attributes
- **THEN** it SHALL validate via Entity, update the Record, and return the updated Entity

#### Scenario: Repository destroy
- **WHEN** `repository.destroy(id)` is called
- **THEN** it SHALL find and destroy the AR Record

### Requirement: Record to Entity mapping
Repository SHALL map AR Record attributes to Entity using `record.attributes.symbolize_keys.slice(*entity_attribute_names)`.

#### Scenario: Attribute mapping
- **WHEN** a Record has columns `id, title, body, created_at, updated_at` and Entity declares matching attributes
- **THEN** `to_entity` SHALL produce an Entity with all matching attributes populated
