## Context

IR 1.0 treats each resource as independent. Scaffold generates isolated entities, records, and endpoints with no foreign keys or associations. The existing AR `reflect_on_all_associations` API already provides the data we need for SchemaRegistry collection — no new DSL required for the basic case.

## Goals / Non-Goals

**Goals:**
- `relations` field in IR per resource
- belongs_to, has_many, has_many_through support
- Foreign keys in migrations
- AR associations in Record
- Foreign key attributes in Entity (district_id)
- Nested resource routing via `parent` field
- SchemaRegistry collects from AR associations
- `from_ir` generates references attributes

**Non-Goals:**
- Polymorphic associations (future)
- Self-referential associations (future)
- Aggregate boundaries (Chunk 6)
- HATEOAS links from relations (Chunk 3)

## Decisions

### 1. Relations in IR — explicit object per association

```json
"relations": {
  "district": { "kind": "belongs_to", "resource": "District", "required": true },
  "comments": { "kind": "has_many",   "resource": "Comment" },
  "owners":   { "kind": "has_many",   "resource": "Owner", "through": "Ownership" }
}
```

Key is the association name. `kind` is required. `resource` references another IR resource by name. `required: true` generates `null: false` on foreign key.

### 2. belongs_to adds foreign key attribute automatically

When IR has `"district": { "kind": "belongs_to", "resource": "District" }`:
- Entity gets `attribute :district_id, :integer`
- Record gets `belongs_to :district, class_name: "DistrictRecord"`
- Migration gets `t.references :district, foreign_key: true`
- Endpoint permit gets `:district_id` added

Developer does NOT manually declare `district_id` in attributes — it's derived from the relation.

### 3. Nested resources use `parent` field

```json
"Comment": {
  "parent": "Parcel",
  "path": "/parcels/{parcel_id}/comments",
  ...
}
```

`parent` causes routing to scope under parent: `scope "/parcels/:parcel_id" { endpoint CommentsEndpoint }`.

### 4. SchemaRegistry reads AR associations via reflection

```ruby
Record.reflect_on_all_associations.each do |assoc|
  # assoc.macro → :belongs_to, :has_many
  # assoc.name → :district
  # assoc.class_name → "DistrictRecord"
end
```

No new DSL needed. AR already knows all associations.

### 5. from_ir passes references as attribute type

For `"district": { "kind": "belongs_to" }`, from_ir generates scaffold argument `district:references`. The existing AR model generator already handles `references` type — creates foreign key column, index, and belongs_to declaration.

## Risks / Trade-offs

- **[Record class name convention]** `belongs_to :district, class_name: "DistrictRecord"` — Record suffix must be explicit to avoid AR looking for `District` model → Convention is clear, enforced by generator
- **[Circular relations]** A belongs_to B, B belongs_to A → IR validation should detect cycles in required belongs_to
- **[from_ir ordering]** Resources must be scaffolded in dependency order (District before Parcel) → from_ir sorts by belongs_to dependencies
