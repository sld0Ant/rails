## Why

Our DDD architecture already contains all the metadata needed to describe the API: Entity declares typed attributes, Endpoint declares routes and permitted params, Record holds DB column info, validators define constraints. This information exists at runtime but can only be accessed programmatically — there is no standard way to export it. Teams need OpenAPI docs for frontend developers, TypeScript types for client generation, JSON Schema for validation contracts. Currently each of these must be written manually and kept in sync.

## What Changes

- New IR (Intermediate Representation) — a documented JSON format (`ddd-ir/1.0`) that captures resource metadata in a language-agnostic way
- New `SchemaRegistry` that collects IR from all Endpoint/Entity/Record classes via runtime introspection
- New `Emitter` system with DI — pluggable adapters that convert IR to spec files
- Built-in OpenAPI 3.x emitter in Rails core (~80 lines Ruby)
- `rake ddd:ir` — dumps `docs/ir.json` (the portable contract)
- `rake ddd:emit[openapi]` — generates `docs/openapi.yaml` from IR
- Reverse direction: `rails generate from_spec docs/openapi.yaml` parses OpenAPI and scaffolds DDD resources
- IR on disk enables external emitters in any language (TS emitter in Node reads `ir.json`, not Ruby)

## Capabilities

### New Capabilities
- `ddd-ir-format`: Documented JSON schema for the Intermediate Representation — the contract between collection and emission
- `schema-registry`: Runtime introspection collector that builds IR from Endpoint + Entity + Record + Routes
- `emitter-base`: Pluggable emitter interface with registration/dispatch via `DDD::Emitter.register(:format, Klass)`
- `emitter-openapi`: Built-in OpenAPI 3.x YAML generator from IR (paths, schemas, operations, request/response bodies)
- `emit-rake-tasks`: `rake ddd:ir` (dump IR JSON) and `rake ddd:emit[format]` (emit to specific format)
- `spec-importer`: Parses OpenAPI YAML → IR → scaffolds DDD resources via existing generators

### Modified Capabilities

## Impact

- **New files in Rails core**: `lib/ddd/` directory with SchemaRegistry, IR, Emitter base + OpenAPI emitter, rake tasks, importer generator
- **No changes** to existing Endpoint/Entity/Repository/Service/Record classes — purely additive
- **No new gem dependencies** — stdlib YAML/JSON only
- **Enables external ecosystem**: `ir.json` on disk can be consumed by npm packages (`@ddd/emit-typescript`), Python tools, or any language
