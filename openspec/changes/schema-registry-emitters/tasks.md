## 1. IR Format

- [x] 1.1 Create `lib/ddd/ir.rb` — IR data class with `.to_json(resources)` and `.from_json(string)` methods, schema version constant `DDD_IR_VERSION = "1.0"`
- [x] 1.2 Create `docs/ddd-ir-schema.md` — human-readable IR format specification with field descriptions, type vocabulary, and examples

## 2. Schema Registry

- [x] 2.1 Create `lib/ddd/schema_registry.rb` — `.collect` method that scans `app/endpoints/*_endpoint.rb`, resolves Entity/Record by convention, builds IR resource array

## 3. Emitter System

- [x] 3.1 Create `lib/ddd/emitter/base.rb` — `Base` class with `#emit(resources)` raising NotImplementedError
- [x] 3.2 Create `lib/ddd/emitter.rb` — module with `.register(format, klass)`, `.emit(format, resources)`, `.formats`, `UnknownFormatError`
- [x] 3.3 Create `lib/ddd/emitter/openapi.rb` — OpenAPI 3.0 emitter generating YAML from IR resources
- [x] 3.4 Register OpenAPI emitter as default in `lib/ddd.rb` loader

## 4. Rake Tasks

- [x] 4.1 Create `lib/tasks/ddd.rake` — `ddd:ir` task (collect → JSON → docs/ir.json) and `ddd:emit[format]` task (collect → emitter → docs/<format file>)

## 5. from_ir Generator

- [x] 5.1 Create `railties/lib/rails/generators/rails/from_ir/from_ir_generator.rb` — reads ir.json, validates schema, loops resources, invokes scaffold for each
- [x] 5.2 Create `railties/lib/rails/generators/rails/from_ir/USAGE` — usage documentation with examples

## 6. IR Format Documentation

- [x] 6.1 Create `docs/ddd-ir-schema.md` — complete IR specification: purpose, format, field reference, type vocabulary, examples, round-trip guarantees, versioning policy
