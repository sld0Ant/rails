## ADDED Requirements

### Requirement: ApplicationService base class
The framework SHALL provide `ApplicationService` as a base class with a private `repository` method that raises `NotImplementedError`.

#### Scenario: Service subclass with repository
- **WHEN** a service subclass overrides `repository` and defines CRUD methods delegating to it
- **THEN** each method SHALL delegate to the corresponding repository method

### Requirement: Scaffold-generated service
The scaffold generator SHALL produce a service with `list_all`, `find`, `create`, `update`, `destroy` methods that delegate to the repository.

#### Scenario: Generated service delegates CRUD
- **WHEN** `rails g scaffold Post title:string` generates `PostService`
- **THEN** `PostService#create(attrs)` SHALL call `PostRepository.new.create(attrs)` and return the result
