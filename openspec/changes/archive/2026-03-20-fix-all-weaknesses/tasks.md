## 1. IR Relation Validation

- [x] 1.1 Update `lib/ddd/ir.rb` validate! — collect resource names, check each relation target exists, raise InvalidIRError if not

## 2. Text Type Round-Trip

- [x] 2.1 Update `lib/ddd/schema_registry.rb` build_attributes — cross-reference Record column sql_type, use "text" when sql_type is text/TEXT
- [x] 2.2 Update `railties/lib/rails/generators/rails/entity/entity_generator.rb` — keep "text" → ":string" mapping (ActiveModel has no :text type) but preserve "text" in IR passthrough

## 3. has_many in from_ir

- [x] 3.1 Update `railties/lib/rails/generators/rails/from_ir/from_ir_generator.rb` — after all scaffolds, second pass: for each belongs_to relation, open parent Record, insert has_many line

## 4. Instrumentation

- [x] 4.1 Update `actionpack/lib/action_dispatch/routing/mapper/endpoint_resources.rb` — wrap endpoint_dispatch body in ActiveSupport::Notifications.instrument, add Rails.error.report in rescue

## 5. Routes Generation

- [x] 5.1 Update `railties/lib/rails/generators/rails/from_ir/from_ir_generator.rb` — add generate_routes method that creates config/routes_ddd.rb with endpoint declarations and nested scoping
