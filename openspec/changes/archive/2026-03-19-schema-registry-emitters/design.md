## Context

The DDD architecture stores API metadata across 4 class types: Entity (typed attributes), Endpoint (resource name, permit list, CRUD operations), Record (DB columns, table name), and Routes (HTTP verbs, paths). All introspectable at runtime. The goal is to collect this into a portable IR format and emit it to multiple output formats.

Proven by introspection test on cadastral-underside app: 3 scaffolded resources (Parcel, District, Owner) — all attributes, types, permits, routes, DB columns extracted automatically from runtime.

## Goals / Non-Goals

**Goals:**
- IR as a documented JSON format (`ddd-ir/1.0`) — language-agnostic contract
- SchemaRegistry collects IR from runtime (zero config, filesystem scan)
- Emitter DI system — register format adapters, dispatch by name
- Built-in OpenAPI 3.x emitter in Rails core
- `rake ddd:ir` dumps `docs/ir.json` for external tools
- `rake ddd:emit[openapi]` generates `docs/openapi.yaml`
- Reverse: `rails g from_spec openapi.yaml` → scaffold DDD resources

**Non-Goals:**
- TypeScript emitter in Ruby (should be a Node package reading ir.json)
- Full OpenAPI coverage (callbacks, webhooks, OAuth, `$ref` chains)
- Swagger UI serving
- GraphQL/Protobuf emitters (future, enabled by architecture)

## Decisions

### 1. IR is a serializable JSON file, not just a Ruby hash

IR lives both in memory (Ruby hashes during collection) and on disk (`docs/ir.json`). The JSON format has a documented schema. This decouples collection (Ruby runtime) from emission (any language).

**Why:** TS emitter written in TS reading `ir.json` is more idiomatic than TS generation via Ruby string concatenation. IR as a file enables ecosystem tools without Ruby dependency.

**Alternatives:** Ruby-only IR (limits to Ruby emitters), protobuf IR (overkill, adds dependency).

### 2. SchemaRegistry discovers endpoints via filesystem scan

Scans `app/endpoints/*_endpoint.rb`, resolves Entity and Record by convention (`PostsEndpoint → Post entity, PostRecord record`). Zero registration needed.

**Why:** Follows Rails autoload conventions. Adding a scaffold = IR automatically includes the new resource.

### 3. Emitter DI with class-level registry

```ruby
DDD::Emitter.register(:openapi, DDD::Emitter::OpenAPI)
DDD::Emitter.emit(:openapi, resources)
```

Users register custom emitters in initializers. Each emitter implements `#emit(resources) → String`.

**Why:** Open/closed principle. Adding GraphQL emitter = 1 class + 1 register call, zero core changes.

### 4. Only OpenAPI emitter ships in Rails core

OpenAPI is the universal API spec — covers 90% of use cases. TypeScript, JSON Schema, GraphQL emitters are external packages that read `ir.json`.

**Why:** Zero deps. OpenAPI generation is ~80 lines of Ruby (YAML hash building). TS emitter is better written in TS. Keeps core minimal.

### 5. Type mapping lives in each emitter, not in IR

IR stores Ruby type symbols (`:integer`, `:string`, `:float`, `:datetime`). Each emitter maps them to its target type system.

**Why:** IR stays format-agnostic. Adding a type mapping for a new format doesn't touch IR or other emitters.

### 6. Importer parses OpenAPI → IR → scaffold commands

`rails g from_spec openapi.yaml` parses the spec into IR resources, then invokes `rails g scaffold Name field:type` for each. Reuses existing generators entirely.

**Why:** No new generator code. Import is a thin parser + loop over scaffold.

## Risks / Trade-offs

- **[Custom Actions not captured]** Action Objects (`Posts::Publish`) are not in IR — only Endpoint CRUD is introspected → Future: add metadata DSL to Action Objects
- **[Import is lossy]** OpenAPI → scaffold loses validators, associations, custom logic → Acceptable for initial generation, developer adds logic after
- **[IR schema evolution]** Adding fields to IR format needs backward compat → Version the schema (`ddd-ir/1.0`)
