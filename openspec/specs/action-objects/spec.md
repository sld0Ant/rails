## ADDED Requirements

### Requirement: ApplicationAction base class
The framework SHALL provide `ApplicationAction` that responds to `#call(env)` (Rack interface). It SHALL construct `ActionDispatch::Request` and `ActionDispatch::Response`, call `handle(req, res)`, and return `res.to_a`.

#### Scenario: Action as Rack app
- **WHEN** an Action subclass is mounted in routes as `post "/posts/:id/publish", to: Posts::Publish`
- **THEN** Rails router SHALL invoke `Posts::Publish.new.call(env)` for matching requests

#### Scenario: Handle method contract
- **WHEN** a subclass implements `def handle(req, res)` setting `res.status`, `res.content_type`, and `res.body`
- **THEN** `call(env)` SHALL return a valid Rack response tuple with those values

#### Scenario: Unimplemented handle
- **WHEN** a subclass does not implement `handle`
- **THEN** `call(env)` SHALL raise `NotImplementedError`
