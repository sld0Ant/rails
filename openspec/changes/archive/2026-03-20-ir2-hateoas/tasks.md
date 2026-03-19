## 1. ApplicationEndpoint — _links support

- [x] 1.1 Update `application_endpoint.rb.tt` — add `resource_relations` class_attribute, add `build_links(entity_hash)` method that generates _links from self + relations, add `with_links(entity_hash)` helper
- [x] 1.2 Update show method to return entity with _links
- [x] 1.3 Update index method to include _links per item (both paginated and flat)

## 2. Endpoint Generator — relations config

- [x] 2.1 Update `endpoint_generator.rb` + `endpoint.rb.tt` — populate `relations:` from reference attributes so scaffold auto-generates link config

## 3. SchemaRegistry — links in IR

- [x] 3.1 Update `schema_registry.rb` — build `links` field from relations (self + belongs_to + has_many)

## 4. E2E Test

- [x] 4.1 Test: show parcel has _links.self + _links.district + _links.notes, index items have _links.self
