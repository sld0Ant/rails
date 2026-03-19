## 1. IR Format Update

- [x] 1.1 Update `lib/ddd/ir.rb` — add `relations` and `parent` to resource schema, bump VERSION to "1.1", update validation to accept optional `relations` object
- [x] 1.2 Update `docs/ddd-ir-schema.md` — document relations field (kind, resource, required, through), parent field, dependency ordering, examples

## 2. Record Generator (associations)

- [x] 2.1 Modify `activerecord/lib/rails/generators/active_record/model/templates/model.rb.tt` — generate `belongs_to` and `has_many` declarations from attributes with `references` type, using `class_name: "XxxRecord"` convention

## 3. Entity Generator (foreign keys)

- [x] 3.1 Modify `railties/lib/rails/generators/rails/entity/entity_generator.rb` — detect `references` type attributes, add `_id` integer attribute for each

## 4. Endpoint Generator (permit foreign keys)

- [x] 4.1 Modify `railties/lib/rails/generators/rails/endpoint/endpoint_generator.rb` — include `_id` fields from references attributes in permitted_fields

## 5. SchemaRegistry (collect relations)

- [x] 5.1 Update `lib/ddd/schema_registry.rb` — add `build_relations` method that reads `Record.reflect_on_all_associations`, maps to IR relations format, includes in resource IR

## 6. from_ir Generator (dependency ordering + references)

- [x] 6.1 Update `railties/lib/rails/generators/rails/from_ir/from_ir_generator.rb` — topological sort resources by belongs_to dependencies, pass `name:references` for belongs_to relations as scaffold arguments

## 7. Nested Resource Routing

- [x] 7.1 Update `actionpack/lib/action_dispatch/routing/mapper/endpoint_resources.rb` — `endpoint` method accepts `scope_path:` option for nested resources
- [x] 7.2 Update `railties/lib/rails/generators/rails/from_ir/from_ir_generator.rb` — generate nested route syntax for resources with `parent` field

## 8. OpenAPI Emitter (relations)

- [x] 8.1 Update `lib/ddd/emitter/openapi.rb` — add foreign key fields to schemas, add `_id` parameters for nested resource paths
