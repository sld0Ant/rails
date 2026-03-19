## 1. Aggregate Boundaries

- [x] 1.1 Update `application_entity.rb.tt` — add `aggregate_root` class_attribute (boolean) and `aggregate(parent)` class method setting `aggregate_parent`
- [x] 1.2 Update `schema_registry.rb` — collect aggregate_root and aggregate_parent into IR

## 2. Value Objects

- [x] 2.1 Update `application_entity.rb.tt` — register `:json` ActiveModel type for JSON-serialized hash attributes
- [x] 2.2 Update entity generator `entity_generator.rb` — map `json` attribute type to `:json`

## 3. Authorization

- [x] 3.1 Update `application_endpoint.rb.tt` — add `authorize_config` class_attribute, accept `authorize:` in resource DSL
- [x] 3.2 Update `endpoint_resources.rb` — endpoint_dispatch extracts `X-User-Role` header, checks against authorize config, returns 403 if forbidden
- [x] 3.3 Update `schema_registry.rb` — collect authorization config into IR

## 4. E2E Test

- [x] 4.1 Test aggregates: entity class attributes set correctly
- [x] 4.2 Test authorization: 403 on unauthorized, 200 on authorized, public ops work without header
