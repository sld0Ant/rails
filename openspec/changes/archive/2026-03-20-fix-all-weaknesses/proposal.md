## Why

Audit identified 5 real weaknesses and 2 mitigable gaps. All fixable within ~170 lines. Fixing them completes the framework for production use.

## What Changes

- IR validation: cross-check relation targets against resource names
- text/string round-trip: preserve `text` type through entity generator and SchemaRegistry
- has_many in from_ir: append has_many to parent Record when scaffolding child
- Instrumentation: add ActiveSupport::Notifications + Rails.error.report in endpoint_dispatch
- Nested routes: from_ir generates routes.rb content with proper scoping

## Capabilities

### New Capabilities
- `nested-route-generation`: from_ir generates routes.rb with endpoint declarations and scoped nesting

### Modified Capabilities
- `ddd-ir-format`: validate! checks relation target existence
- `schema-registry`: uses Record column sql_type to distinguish text vs string
- `spec-importer`: from_ir appends has_many to parent Records, generates routes.rb
- `endpoint-routing`: endpoint_dispatch includes instrumentation and error reporting

## Impact

- **Modified**: ir.rb, schema_registry.rb, entity_generator.rb, endpoint_resources.rb, from_ir_generator.rb
- **No new files, no new dependencies**
