## ADDED Requirements

### Requirement: ApplicationEndpoint base class
The framework SHALL provide `ApplicationEndpoint` with `resource` class method accepting `name`, `service:`, and `permit:` options. It SHALL implement `index`, `show`, `create`, `update`, `destroy` instance methods that return Rack response tuples `[status, headers, body]`.

#### Scenario: Endpoint index
- **WHEN** `endpoint.index(params)` is called
- **THEN** it SHALL call `service.list_all` and return `[200, {"content-type" => "application/json"}, [json_array]]`

#### Scenario: Endpoint show
- **WHEN** `endpoint.show(params)` is called with `params[:id]`
- **THEN** it SHALL call `service.find(id)` and return `[200, headers, [entity_json]]`

#### Scenario: Endpoint create success
- **WHEN** `endpoint.create(params)` is called with valid data
- **THEN** it SHALL extract permitted params, call `service.create`, and return `[201, headers, [entity_json]]`

#### Scenario: Endpoint create failure
- **WHEN** `endpoint.create(params)` is called with invalid data
- **THEN** it SHALL return `[422, headers, [errors_json]]` with entity validation errors

#### Scenario: Endpoint update success
- **WHEN** `endpoint.update(params)` is called with valid data
- **THEN** it SHALL call `service.update(id, attrs)` and return `[200, headers, [entity_json]]`

#### Scenario: Endpoint destroy
- **WHEN** `endpoint.destroy(params)` is called
- **THEN** it SHALL call `service.destroy(id)` and return `[204, {}, []]`

### Requirement: Declarative resource configuration
A subclass SHALL configure itself with `resource :name, service: ServiceClass, permit: [:fields]` in a single declaration.

#### Scenario: Minimal endpoint definition
- **WHEN** `PostsEndpoint` declares `resource :post, service: PostService, permit: [:title, :body]`
- **THEN** all 5 CRUD methods SHALL use `PostService` and filter params to only `:title` and `:body`
