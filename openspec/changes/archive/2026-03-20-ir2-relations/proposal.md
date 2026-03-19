## Why

IR 1.0 describes isolated resources. Real applications have a graph of connected resources: a Parcel belongs_to a District, has_many Comments, has_many Owners through Ownerships. Without relations in IR, `from_ir` generates disconnected tables with no foreign keys, associations, or nested routes. This is the foundation for HATEOAS links, nested resources, and aggregate boundaries in future chunks.

## What Changes

- IR format gains `relations` field per resource describing belongs_to, has_many, has_many-through associations
- Entity generator adds foreign key attributes (e.g. `district_id`) for belongs_to relations
- Record template generates AR associations (belongs_to, has_many)
- Migration generator adds foreign key references and indexes
- SchemaRegistry collects relations from AR `reflect_on_all_associations`
- `from_ir` generator passes relation data to scaffold (references attributes)
- Endpoint routing supports nested resources via `parent` field

## Capabilities

### New Capabilities
- `ir-relations`: IR resource `relations` field with belongs_to, has_many, has_many-through associations
- `nested-resources`: Resources with `parent` field generate scoped routes (/parcels/:parcel_id/comments)

### Modified Capabilities
- `ddd-ir-format`: IR schema extended from 1.0 to 1.1 with `relations` and `parent` fields
- `schema-registry`: Collects associations from Record class via AR reflection
- `ddd-generators`: Entity, Record, and Endpoint generators handle relation attributes
- `spec-importer`: `from_ir` passes `references` type attributes for belongs_to relations

## Impact

- **IR version**: 1.0 → 1.1 (backward compatible — `relations` is optional)
- **Modified files**: ir.rb, schema_registry.rb, entity template, record template, endpoint_resources.rb, from_ir generator, entity/record/endpoint generators
- **No new dependencies**
