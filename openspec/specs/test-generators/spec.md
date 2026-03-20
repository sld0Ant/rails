## ADDED Requirements

### Requirement: Entity test generated
Entity generator SHALL create `test/entities/<name>_test.rb` with unit test for attribute presence and persisted? behavior.

#### Scenario: Scaffold generates entity test
- **WHEN** `rails g scaffold Post title:string` is run
- **THEN** `test/entities/post_test.rb` SHALL exist with test class inheriting ActiveSupport::TestCase

### Requirement: Service test generated
Service generator SHALL create `test/services/<name>_service_test.rb` with test for CRUD methods.

#### Scenario: Scaffold generates service test
- **WHEN** `rails g scaffold Post title:string` is run
- **THEN** `test/services/post_service_test.rb` SHALL exist

### Requirement: Repository test generated
Repository generator SHALL create `test/repositories/<name>_repository_test.rb` with integration test.

#### Scenario: Scaffold generates repository test
- **WHEN** `rails g scaffold Post title:string` is run
- **THEN** `test/repositories/post_repository_test.rb` SHALL exist

### Requirement: Endpoint test generated
Endpoint generator SHALL create `test/endpoints/<name>_endpoint_test.rb` with HTTP integration test.

#### Scenario: Scaffold generates endpoint test
- **WHEN** `rails g scaffold Post title:string` is run
- **THEN** `test/endpoints/posts_endpoint_test.rb` SHALL exist with tests for index, show, create, update, destroy

### Requirement: Destroy removes test files
`rails destroy scaffold Post` SHALL remove all 4 test files.

#### Scenario: Clean destroy
- **WHEN** `rails destroy scaffold Post` is run
- **THEN** all 4 test files SHALL be removed
