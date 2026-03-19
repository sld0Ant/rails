## 1. Error Handling

- [x] 1.1 Update `actionpack/lib/action_dispatch/routing/mapper/endpoint_resources.rb` — wrap endpoint_dispatch lambda body in rescue: RecordNotFound → 404 JSON, StandardError → 500 JSON

## 2. Cache Headers

- [x] 2.1 Update `railties/lib/rails/generators/rails/app/templates/app/endpoints/application_endpoint.rb.tt` — add `cache_config` class_attribute to resource DSL, add `apply_cache_headers(action, headers)` method that merges cache-control into response headers
- [x] 2.2 Update response tuples in index/show/create/update to call apply_cache_headers

## 3. E2E Test

- [x] 3.1 Test 404 on non-existent resource, test cache-control headers when configured, test backward compat without cache
