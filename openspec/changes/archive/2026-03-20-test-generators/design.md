## Context

Rails scaffold generates controller + model tests via `hook_for :test_framework`. Our generators don't have this hook. Need to add test templates that match our DDD layers.

## Decisions

### 1. Test types per layer

- **Entity test**: PORO unit test. No DB, no HTTP. Tests validations, persisted?, transitions.
- **Service test**: Unit test with real repository (needs DB for integration). Tests CRUD delegation.
- **Repository test**: Integration test. Creates records, verifies entity mapping.
- **Endpoint test**: HTTP integration via Rack::Test. Tests status codes, JSON shape, _links.

### 2. Template approach — standalone test files, not through test_unit scaffold hook

Rails test_unit scaffold hook generates controller functional tests. Our layers are different. Simpler approach: each generator (entity, service, repository, endpoint) creates its own test file directly via `template`, no hook_for complexity.

### 3. Test directory structure

```
test/
  entities/post_test.rb
  services/post_service_test.rb
  repositories/post_repository_test.rb
  endpoints/posts_endpoint_test.rb
```
