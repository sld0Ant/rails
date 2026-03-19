## ADDED Requirements

### Requirement: IR JSON format specification
The IR SHALL be a JSON document with `$schema: "ddd-ir/1.0"` and a `resources` array. Each resource SHALL contain: `name` (string), `plural` (string), `path` (string), `attributes` (object mapping name → {type, nullable, readonly}), `permit` (array of writable field names), `operations` (array of {action, method, path}), `validators` (array of {type, fields}).

#### Scenario: Valid IR document
- **WHEN** SchemaRegistry collects from a Parcel endpoint with `attribute :area, :float` and `permit: [:area]`
- **THEN** IR JSON SHALL contain `{"name": "Parcel", "plural": "parcels", "path": "/parcels", "attributes": {"area": {"type": "float", "nullable": true, "readonly": false}}, "permit": ["area"], "operations": [...]}`

#### Scenario: IR type vocabulary
- **WHEN** Entity declares attributes with types `:integer`, `:string`, `:float`, `:boolean`, `:datetime`, `:date`, `:decimal`, `:text`
- **THEN** IR SHALL use these exact type strings — no mapping, raw Ruby type names

#### Scenario: Readonly attributes
- **WHEN** attribute is `id`, `created_at`, or `updated_at`
- **THEN** IR SHALL mark it `"readonly": true`

#### Scenario: Operations from endpoint
- **WHEN** endpoint has 5 CRUD operations
- **THEN** IR operations SHALL contain exactly 5 entries with correct HTTP methods and path patterns using `{id}` placeholder

### Requirement: IR serialization and deserialization
`DDD::IR` SHALL provide `.to_json(resources)` and `.from_json(string)` class methods for round-trip conversion.

#### Scenario: Round-trip
- **WHEN** IR is serialized to JSON and deserialized back
- **THEN** the result SHALL be structurally identical to the original
