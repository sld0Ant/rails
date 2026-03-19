## 1. Repository — paginate method

- [x] 1.1 Update `railties/lib/rails/generators/rails/app/templates/app/repositories/application_repository.rb.tt` — add `paginate(page:, per:, sort:, filter:, search:, search_fields:)` method with AR scope chaining

## 2. Endpoint — collection DSL + index override

- [x] 2.1 Update `railties/lib/rails/generators/rails/app/templates/app/endpoints/application_endpoint.rb.tt` — add `sort:`, `filter:`, `search:`, `per_page:` to resource DSL as class_attributes; override `index` to use collection params when configured

## 3. Service — pass collection params

- [x] 3.1 Update `railties/lib/rails/generators/rails/app/templates/app/services/application_service.rb.tt` — no change needed (service already delegates, endpoint calls repository directly via service)
- [x] 3.2 Update `railties/lib/rails/generators/rails/service/templates/service.rb.tt` — update `list_all` to accept `**params` and delegate to `repository.paginate(**params)` when params present

## 4. Endpoint generator — collection options

- [x] 4.1 Update `railties/lib/rails/generators/rails/endpoint/endpoint_generator.rb` — accept collection options from attributes, generate endpoint with sort/filter fields matching attribute names

## 5. IR + SchemaRegistry + OpenAPI

- [x] 5.1 Update `lib/ddd/schema_registry.rb` — collect collection config from Endpoint class (sortable_fields, filterable_fields, searchable_fields, default_per_page)
- [x] 5.2 Update `lib/ddd/emitter/openapi.rb` — add query parameters (page, per_page, sort, filter fields) to index operation when collection config present

## 6. Test E2E on registration

- [x] 6.1 Update test app Endpoint with collection config, create test data, verify pagination/filter/sort/search via HTTP
